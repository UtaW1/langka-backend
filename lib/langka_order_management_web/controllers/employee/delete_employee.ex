defmodule LangkaOrderManagementWeb.DeleteEmployee do
  alias LangkaOrderManagement.Employee
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with employee when not is_nil(employee) <- Employee.get_employee(id),
         {:ok, _} <- Employee.delete_employee(employee) do
      Plug.Conn.send_resp(conn, 204, "")
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "employee not found", "")

      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})
    end
  end
end
