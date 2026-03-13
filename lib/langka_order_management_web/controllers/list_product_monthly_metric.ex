defmodule LangkaOrderManagementWeb.ListProductMonthlyMetric do
  alias LangkaOrderManagement.Product

  def rules(_), do: %{}

  def perform(conn, _args) do
    metrics = Product.list_monthly_product_quantity_metrics()

    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_product_monthly_metric.json", data: metrics)
  end

  defmodule View do
    def render("list_product_monthly_metric.json", %{data: metrics}) do
      Enum.map(metrics, & %{
        product_id: &1.product_id,
        product_name: &1.product_name,
        total_quantity: &1.total_quantity
      })
    end
  end
end
