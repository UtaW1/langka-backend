defmodule LangkaOrderManagementWeb.ListTransaction do
  alias LangkaOrderManagement.Account

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 16}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "status" => [required: false, nullable: true, cast: :string, type: :string, in: ["pending", "completed", "cancelled"]],
      "employee_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, filters) do
    {transactions, count} = Account.list_all_transactions(filters)

    conn
    |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_transactions.json", data: transactions)
  end

  defmodule View do
    def render("list_transactions.json", %{data: transactions}) do
      Enum.map(transactions, & %{
        id: &1.id,
        invoice_id: &1.invoice_id,
        bill_price_as_usd: &1.bill_price_as_usd,
        bill_price_before_discount_as_usd: &1.bill_price_before_discount_as_usd,
        bill_price_after_discount_as_usd: &1.bill_price_after_discount_as_usd,
        discount_amount_as_usd: &1.discount_amount_as_usd,
        promotion_discount_as_percent: &1.discount_as_percent_applied || (&1 |> Map.get(:promotion_apply, %{}) |> Map.get(:discount_as_percent)),
        table_number: &1.seating_table.table_number,
        employee: &1 |> Map.get(:employee, %{}) |> Map.get(:name),
        status: &1.status,
        user_id: &1.user_id,
        promotion_id: &1.promotion_apply_id,
        inserted_at: &1.inserted_at,
        products_orders: Enum.map(&1.product_transactions, fn pt ->
          %{
            product_id: pt.product_id,
            name: pt.product.name,
            quantity: pt.quantity,
            sugar_level: pt.sugar_level,
            ice_level: pt.ice_level,
            order_note: pt.order_note
          }
        end)
      })
    end
  end
end
