defmodule LangkaOrderManagementWeb.CreateEmployee do
  alias LangkaOrderManagement.Employee
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "name" => [required: true, nullable: false, type: :string],
      "phone" => [required: true, nullable: false, custom: &ControllerUtils.validate_phone_number/1]
    }
  end

  def perform(conn, args) do
    with {:ok, employee} <- Employee.create_employee(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_employee.json", data: employee)
    else
      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("400.json", %{error: :changeset_error, message: "changeset error #{inspect(changeset)}"})
    end
  end

  defmodule View do
    def render("create_employee.json", %{data: employee}) do
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
