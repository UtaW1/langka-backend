defmodule LangkaOrderManagementWeb.GetTransaction do
  alias LangkaOrderManagement.Account

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, type: :string]
    }
  end

  def perform(conn, %{"id" => id}) do
    with transaction when not is_nil(transaction) <- Account.get_transaction_by_id(id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("get_transaction.json", data: transaction)
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "transaction not found", "")
    end
  end

  defmodule View do
    def render("get_transaction.json", %{data: transaction}) do
      promotion_discount_as_percent =
        transaction.discount_as_percent_applied ||
          case transaction.promotion_apply do
            %{discount_as_percent: discount_as_percent} -> discount_as_percent
            _ -> nil
          end

      user_name =
        case transaction.user do
          %{username: username} -> username
          _ -> nil
        end

      user_phone =
        case transaction.user do
          %{phone_number: phone_number} -> phone_number
          _ -> nil
        end

      table_number =
        case transaction.seating_table do
          %{table_number: number} -> number
          _ -> nil
        end

      %{
        id: transaction.id,
        invoice_id: transaction.invoice_id,
        bill_price_as_usd: transaction.bill_price_as_usd,
        bill_price_before_discount_as_usd: transaction.bill_price_before_discount_as_usd,
        bill_price_after_discount_as_usd: transaction.bill_price_after_discount_as_usd,
        discount_amount_as_usd: transaction.discount_amount_as_usd,
        promotion_discount_as_percent: promotion_discount_as_percent,
        table_number: table_number,
        user_id: transaction.user_id,
        user_name: user_name,
        user_phone: user_phone,
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
    end
  end
end
