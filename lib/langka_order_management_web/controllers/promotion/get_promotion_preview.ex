defmodule LangkaOrderManagementWeb.GetPromotionPreview do
  alias LangkaOrderManagement.{Account, Promotion}
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "phone_number" => [required: false, nullable: true, custom: &ControllerUtils.validate_phone_number/1]
    }
  end

  def perform(conn, %{"phone_number" => nil}) do
    render_preview(conn, Promotion.preview_next_order_discount(nil))
  end

  def perform(conn, %{"phone_number" => phone_number}) do
    user = Account.get_customer_by_phone_number(phone_number)
    user_id = if user, do: user.id, else: nil

    render_preview(conn, Promotion.preview_next_order_discount(user_id))
  end

  def perform(conn, _args) do
    render_preview(conn, Promotion.preview_next_order_discount(nil))
  end

  defp render_preview(conn, preview) do
    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("promotion_preview.json", data: preview)
  end

  defmodule View do
    def render("promotion_preview.json", %{data: preview}) do
      promotion = Map.get(preview, :promotion)

      %{
        will_have_discount_on_next_order: Map.get(preview, :will_have_discount_on_next_order, false),
        current_progress_count: Map.get(preview, :current_progress_count, 0),
        required_transaction_count: Map.get(preview, :required_transaction_count),
        remaining_orders_before_discount: Map.get(preview, :remaining_orders_before_discount),
        promotion: render_promotion(promotion)
      }
    end

    defp render_promotion(nil), do: nil

    defp render_promotion(promotion) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        status: promotion.status
      }
    end
  end
end
