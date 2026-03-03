defmodule LangkaOrderManagement.Report do
  @moduledoc false

  alias LangkaOrderManagement.{Repo, Account.Transaction}
  import Ecto.Query, warn: false
  require Elixlsx

  def list_transactions_for_export(%{"start_datetime" => start_datetime, "end_datetime" => end_datetime}) do
    transactions =
      Transaction
      # |> join(:inner, [t], _ in assoc(t, :product_transactions))
      # |> join(:inner, [_, pt], _ in assoc(pt, :product))
      |> where([t], t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime)
      |> where([t], t.status == ^"completed")
      |> order_by([t], desc: :inserted_at)
      |> select([t], %{
        id: t.id,
        bill_price_as_usd: t.bill_price_as_usd,
        invoice_id: t.invoice_id,
        table_number: t.table_number,
        user_id: t.user_id,
        promotion_apply_id: t.promotion_apply_id,
        transaction_datetime: t.inserted_at
      })
      |> Repo.all()

    columns = ~w(id bill_price_as_usd invoice_id table_number user_id promotion_apply_id transaction_datetime)a

    %{
      rows: transactions,
      columns: columns
    }
  end

  def construct_xlsx_for_export(%{columns: columns, rows: rows}, header, params) do
    start_date = Map.get(params, "start_datetime")
    end_date = Map.get(params, "end_datetime")

    dir = Map.get(params, "dir", "#{String.replace(header, " ", "-")}.xlsx")

    string_columns = Enum.map(columns, fn col ->
      case col do
        col when is_atom(col) -> Atom.to_string(col)
        col -> col
      end
    end)

    metadata_rows = [
      [header] ++ List.duplicate("", length(columns) - 1),
      ["Generated on: #{Date.utc_today()}"] ++ List.duplicate("", length(columns) - 1),
      ["From #{start_date} To #{end_date}"] ++ List.duplicate("", length(columns) - 1),
      List.duplicate("", length(columns))
    ]

    data_rows = Enum.map(rows, fn row ->
      Enum.map(columns, fn col ->
        "#{Map.get(row, col, "")}"
      end)
    end)

    all_rows = metadata_rows ++ [string_columns] ++ data_rows

    sheet = %Elixlsx.Sheet{
      name: "Exported Data",
      rows: all_rows
    }

    workbook = %Elixlsx.Workbook{sheets: [sheet]}

    {:ok, {_file_path, binary_data}} = Elixlsx.write_to_memory(workbook, dir)

    binary_data
  end
end
