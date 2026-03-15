defmodule LangkaOrderManagementWeb.GetEmployee do
  alias LangkaOrderManagement.Employee
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with employee when not is_nil(employee) <- Employee.get_employee(id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("get_employee.json", data: employee)
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "employee not found", "")
    end
  end

  defmodule View do
    def render("get_employee.json", %{data: employee}) do
      %{
        id: employee.id,
        name: employee.name,
        phone: employee.phone,
        removed_datetime: employee.removed_datetime,
        inserted_at: employee.inserted_at,
        updated_at: employee.updated_at
      }
    end
  end
end
