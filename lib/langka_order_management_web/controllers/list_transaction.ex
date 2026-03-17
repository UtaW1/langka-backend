defmodule LangkaOrderManagementWeb.ListTransaction do
  alias LangkaOrderManagement.Account
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 16}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "status" => [required: false, nullable: true, cast: :string, type: :string, in: ["pending", "completed", "cancelled"]],
      "employee_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 1],
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
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
      Enum.map(transactions, fn transaction ->
        promotion_discount_as_percent =
          transaction.discount_as_percent_applied ||
            case transaction.promotion_apply do
              %{discount_as_percent: discount_as_percent} -> discount_as_percent
              _ -> nil
            end

        employee_name =
          case transaction.employee do
            %{name: name} -> name
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
          table_number: transaction.seating_table.table_number,
          employee: employee_name,
          status: transaction.status,
          user_id: transaction.user_id,
          promotion_id: transaction.promotion_apply_id,
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
      |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    end
  end
end
