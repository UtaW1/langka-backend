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

  def list_monthly_table_usage_metrics do
    start_date = Date.beginning_of_month(Date.utc_today())
    end_date = Date.end_of_month(Date.utc_today())

    Transaction
    |> join(:inner, [t], table in assoc(t, :seating_table))
    |> where([t, _table], t.status == ^"completed")
    |> where([t, _table], type(t.inserted_at, :date) >= ^start_date and type(t.inserted_at, :date) <= ^end_date)
    |> group_by([_t, table], [table.id, table.table_number])
    |> select([t, table], %{
      seating_table_id: table.id,
      table_number: table.table_number,
      usage_count: count(t.id)
    })
    |> order_by([t, table], [desc: count(t.id), asc: table.table_number])
    |> Repo.all()
  end
end
