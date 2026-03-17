defmodule LangkaOrderManagementWeb.ListPromotionProgressionMetric do
  alias LangkaOrderManagement.Promotion

  def rules(_), do: %{}

  def perform(conn, _args) do
    metrics = Promotion.list_active_promotion_progression_metrics()

    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_promotion_progression_metric.json", data: metrics)
  end

  defmodule View do
    def render("list_promotion_progression_metric.json", %{data: metrics}) do
      Enum.map(metrics, &%{
        user_id: &1.user_id,
        username: &1.username,
        phone_number: &1.phone_number,
        promotion_id: &1.promotion_id,
        discount_as_percent: &1.discount_as_percent,
        transaction_count_to_get_discount: &1.transaction_count_to_get_discount,
        current_progress_count: &1.current_progress_count,
        remaining_orders_before_discount: &1.remaining_orders_before_discount,
        will_have_discount_on_next_order: &1.will_have_discount_on_next_order
      })
    end
  end
end
