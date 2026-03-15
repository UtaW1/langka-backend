defmodule LangkaOrderManagementWeb.UpdateEmployee do
  alias LangkaOrderManagement.Employee
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer],
      "name" => [required: false, nullable: true, type: :string],
      "phone" => [required: false, nullable: true, custom: &ControllerUtils.validate_phone_number/1]
    }
  end

  def perform(conn, %{"id" => id} = args) do
    with employee when not is_nil(employee) <- Employee.get_employee(id),
         {:ok, updated_employee} <- Employee.update_employee(employee, args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_employee.json", data: updated_employee)
    else
      nil ->
        ControllerUtils.render_error(conn, 422, "422.json", :employee_not_found, "")

      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})

      err ->
        ControllerUtils.render_error(conn, 500, "500.json", :unexpected_error, "#{inspect(err)}")
    end
  end

  defmodule View do
    def render("update_employee.json", %{data: employee}) do
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
