defmodule LangkaOrderManagement.SeatingTable do
  alias LangkaOrderManagement.{
    SeatingTable.SeatingTable,
    Account.Transaction,
    ContextUtil,
    Repo
  }
  import Ecto.Query, warn: false

  @pending_limit 3

  def pending_order_table_limit(table_id) do
    Transaction
    |> where([t], t.seating_table_id == ^table_id)
    |> where([t], t.status == ^"pending")
    |> group_by([t], t.seating_table_id)
    |> having([t], count() >= ^@pending_limit)
    |> Repo.exists?()
  end

  def list_seating_tables_with_paging(filters) do
    query =
      SeatingTable
      |> ContextUtil.list(filters)

    tables = Repo.all(query)

    count =
      query
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([table], count(table.id))
      |> Repo.one()

    {tables, count}
  end

  def get_seating_table(id), do: Repo.get(SeatingTable, id)

  def create_seating_table(attrs) do
    %SeatingTable{}
    |> SeatingTable.changeset(attrs)
    |> Repo.insert()
  end

  def update_seating_table(%SeatingTable{} = table, attrs) do
    table
    |> SeatingTable.changeset(attrs)
    |> Repo.update()
  end

  def delete_seating_table(%SeatingTable{} = table) do
    Repo.delete(table)
  end

  def list_table_transactions(filters) do
    query =
      SeatingTable
      |> ContextUtil.list(filters)
      |> preload([table], transactions: ^from(transaction in Transaction,
        where: transaction.status == ^"completed",
        order_by: [desc: transaction.id],
        preload: [product_transactions: :product]
      ))

    tables = Repo.all(query)

    count =
      query
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:preload)
      |> select([table], count(table.id))
      |> Repo.one()

    {tables, count}
  end

  def list_monthly_table_usage_metrics(filters \\ %{}) do
    {start_datetime, end_datetime} = resolve_metric_datetime_range(filters)

    Transaction
    |> join(:inner, [t], table in assoc(t, :seating_table))
    |> where([t, _table], t.status == ^"completed")
    |> where([t, _table], t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime)
    |> group_by([_t, table], [table.id, table.table_number])
    |> select([t, table], %{
      seating_table_id: table.id,
      table_number: table.table_number,
      usage_count: count(t.id)
    })
    |> order_by([t, table], [desc: count(t.id), asc: table.table_number])
    |> Repo.all()
  end

  defp resolve_metric_datetime_range(filters) do
    start_datetime =
      case Map.get(filters, "start_datetime") do
        %DateTime{} = dt -> dt
        _ ->
          Date.utc_today()
          |> Date.beginning_of_month()
          |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      end

    end_datetime =
      case Map.get(filters, "end_datetime") do
        %DateTime{} = dt -> dt
        _ ->
          Date.utc_today()
          |> Date.end_of_month()
          |> DateTime.new!(~T[23:59:59], "Etc/UTC")
      end

    {start_datetime, end_datetime}
  end
end
