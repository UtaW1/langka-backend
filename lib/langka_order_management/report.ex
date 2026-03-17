defmodule LangkaOrderManagement.Report do
  @moduledoc false

  alias LangkaOrderManagement.{Repo, Account.Transaction, Account.User}
  import Ecto.Query, warn: false
  require Elixlsx

  def list_transactions_for_export(%{"start_datetime" => start_datetime, "end_datetime" => end_datetime}) do
    transactions =
      Transaction
      |> where([t], t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime)
      |> where([t], t.status == ^"completed")
      |> preload([t], [:seating_table, :promotion_apply, product_transactions: :product])
      |> order_by([t], desc: :inserted_at)
      |> Repo.all()
      |> Enum.map(fn transaction ->
        products_bought =
          transaction.product_transactions
          |> Enum.map(fn product_transaction ->
            product_name =
              case product_transaction.product do
                %{name: name} -> name
                _ -> "unknown_product"
              end

            "#{product_name} x#{product_transaction.quantity}"
          end)
          |> Enum.join(" | ")

        table_number =
          case transaction.seating_table do
            %{table_number: number} -> number
            _ -> nil
          end

        promotion_discount_as_percent =
          transaction.discount_as_percent_applied ||
            case transaction.promotion_apply do
              %{discount_as_percent: discount_as_percent} -> discount_as_percent
              _ -> nil
            end

        %{
          id: transaction.id,
          invoice_id: transaction.invoice_id,
          user_id: transaction.user_id,
          table_number: table_number,
          promotion_apply_id: transaction.promotion_apply_id,
          promotion_discount_as_percent: promotion_discount_as_percent,
          bill_price_before_discount_as_usd: transaction.bill_price_before_discount_as_usd,
          discount_amount_as_usd: transaction.discount_amount_as_usd,
          bill_price_after_discount_as_usd: transaction.bill_price_after_discount_as_usd,
          bill_price_as_usd: transaction.bill_price_as_usd,
          products_bought: products_bought,
          transaction_datetime: transaction.inserted_at
        }
      end)

    columns = ~w(
      id
      invoice_id
      user_id
      table_number
      promotion_apply_id
      promotion_discount_as_percent
      bill_price_before_discount_as_usd
      discount_amount_as_usd
      bill_price_after_discount_as_usd
      bill_price_as_usd
      products_bought
      transaction_datetime
    )a

    %{
      rows: transactions,
      columns: columns
    }
  end

  def list_users_for_export(%{"start_datetime" => start_datetime, "end_datetime" => end_datetime}) do
    users =
      User
      |> where([u], u.role == ^"customer")
      |> join(
        :left,
        [u],
        t in Transaction,
        on:
          t.user_id == u.id and
            t.status == ^"completed" and
            t.inserted_at >= ^start_datetime and
            t.inserted_at <= ^end_datetime
      )
      |> group_by([u, _t], [u.id, u.username, u.phone_number, u.inserted_at])
      |> select([u, t], %{
        id: u.id,
        username: u.username,
        phone_number: u.phone_number,
        total_completed_transactions: count(t.id),
        total_revenue_generated: fragment("COALESCE(?, 0)", sum(t.bill_price_as_usd)),
        user_created_at: u.inserted_at
      })
      |> order_by([u, _t], [desc: u.inserted_at])
      |> Repo.all()

    columns = ~w(
      id
      username
      phone_number
      total_completed_transactions
      total_revenue_generated
      user_created_at
    )a

    %{
      rows: users,
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
