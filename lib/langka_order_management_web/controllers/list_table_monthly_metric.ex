defmodule LangkaOrderManagementWeb.ListTableMonthlyMetric do
  alias LangkaOrderManagement.SeatingTable

  def rules(_), do: %{}

  def perform(conn, _args) do
    metrics = SeatingTable.list_monthly_table_usage_metrics()

    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_table_monthly_metric.json", data: metrics)
  end

  defmodule View do
    def render("list_table_monthly_metric.json", %{data: metrics}) do
      Enum.map(metrics, & %{
        seating_table_id: &1.seating_table_id,
        table_number: &1.table_number,
        usage_count: &1.usage_count
      })
    end
  end
end
