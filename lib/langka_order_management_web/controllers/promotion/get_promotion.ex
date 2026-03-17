defmodule LangkaOrderManagementWeb.GetPromotion do
  alias LangkaOrderManagement.Promotion

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with promotion_with_transactions when not is_nil(promotion_with_transactions) <- Promotion.get_promotion_with_transactions(id)
      do
        conn
        |> Phoenix.Controller.put_view(__MODULE__.View)
        |> Phoenix.Controller.render("get_promotion.json", data: promotion_with_transactions)
      else
        nil ->
          conn
          |> Plug.Conn.put_status(404)
          |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
          |> Phoenix.Controller.render("404.json", %{error: {"resource not found", "promotion does not exist"}})
    end
  end

  defmodule View do
    def render("get_promotion.json", %{data: %{promotion: promotion, transactions: transactions}}) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        status: promotion.status,
        transactions:
          Enum.map(transactions, fn transaction ->
            %{
              id: transaction.id,
              status: transaction.status,
              invoice_id: transaction.invoice_id,
              user_id: transaction.user_id,
              user_name: transaction.user && transaction.user.username,
              employee_id: transaction.employee_id,
              employee_name: transaction.employee && transaction.employee.name,
              table_number: transaction.seating_table && transaction.seating_table.table_number,
              bill_price_as_usd: transaction.bill_price_as_usd,
              bill_price_before_discount_as_usd: transaction.bill_price_before_discount_as_usd,
              bill_price_after_discount_as_usd: transaction.bill_price_after_discount_as_usd,
              discount_amount_as_usd: transaction.discount_amount_as_usd,
              discount_as_percent_applied: transaction.discount_as_percent_applied,
              inserted_at: transaction.inserted_at,
              products_orders:
                Enum.map(transaction.product_transactions, fn product_transaction ->
                  %{
                    product_id: product_transaction.product_id,
                    product_name: product_transaction.product && product_transaction.product.name,
                    quantity: product_transaction.quantity,
                    sugar_level: product_transaction.sugar_level,
                    ice_level: product_transaction.ice_level,
                    order_note: product_transaction.order_note
                  }
                end)
            }
          end)
      }
    end
  end
end
