defmodule LangkaOrderManagementWeb.ListPromotionUsageMetric do
  alias LangkaOrderManagement.Promotion
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
    }
  end

  def perform(conn, args) do
    metrics = Promotion.list_active_promotion_usage_metrics(args)

    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_promotion_usage_metric.json", data: metrics)
  end

  defmodule View do
    def render("list_promotion_usage_metric.json", %{data: metrics}) do
      Enum.map(metrics, &%{
        promotion_id: &1.promotion_id,
        transaction_count_to_get_discount: &1.transaction_count_to_get_discount,
        discount_as_percent: &1.discount_as_percent,
        status: &1.status,
        total_applied_transactions: &1.total_applied_transactions
      })
    end
  end
end
