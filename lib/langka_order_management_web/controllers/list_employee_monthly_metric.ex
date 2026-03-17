defmodule LangkaOrderManagementWeb.ListEmployeeMonthlyMetric do
  alias LangkaOrderManagement.Account
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
    }
  end

  def perform(conn, args) do
    metrics = Account.list_monthly_employee_transaction_metrics(args)

    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_employee_monthly_metric.json", data: metrics)
  end

  defmodule View do
    def render("list_employee_monthly_metric.json", %{data: metrics}) do
      Enum.map(metrics, & %{
        employee_id: &1.employee_id,
        employee_name: &1.employee_name,
        completed_orders: &1.completed_orders,
        cancelled_orders: &1.cancelled_orders
      })
    end
  end
end
