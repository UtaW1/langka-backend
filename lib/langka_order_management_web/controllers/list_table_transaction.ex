defmodule LangkaOrderManagementWeb.ListTableTransaction do
  alias LangkaOrderManagement.SeatingTable

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 16}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0]
    }
  end

  def perform(conn, filters) do
    {tables, count} = SeatingTable.list_table_transactions(filters)

    conn
    |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_table_transactions.json", data: tables)
  end

  defmodule View do
    def render("list_table_transactions.json", %{data: tables}) do
      Enum.map(tables, & %{
        id: &1.id,
        table_number: &1.table_number,
        seating_count: &1.seating_count,
        transactions: Enum.map(&1.transactions, fn transaction ->
          %{
            id: transaction.id,
            invoice_id: transaction.invoice_id,
            bill_price_as_usd: transaction.bill_price_as_usd,
            user_id: transaction.user_id,
            promotion_id: transaction.promotion_apply_id,
            status: transaction.status,
            inserted_at: transaction.inserted_at,
            products_orders: Enum.map(transaction.product_transactions, fn pt ->
              %{
                product_id: pt.product_id,
                name: pt.product.name,
                quantity: pt.quantity,
                sugar_level: pt.sugar_level,
                ice_level: pt.ice_level,
                order_note: pt.order_note
              }
            end)
          }
        end)
      })
    end
  end
end
