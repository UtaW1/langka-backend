defmodule LangkaOrderManagementWeb.ListEmployee do
  alias LangkaOrderManagement.Employee
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "label" => [required: false, nullable: true, type: :string],
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 32}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "is_removed" => [required: false, nullable: true, custom: &ControllerUtils.validate_boolean/1],
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
    }
  end

  def perform(conn, %{"cursor_id" => "" <> _, "page_number" => page_number}) when not is_nil(page_number) do
    conn
    |> Plug.Conn.put_status(:bad_request)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render("400.json", %{error: :invalid_request, message: "cannot supply both cursor_id and page_number"})
  end

  def perform(conn, %{"cursor_id" => cursor_id, "page_number" => page_number}) when is_nil(page_number) and is_nil(cursor_id) do
    conn
    |> Plug.Conn.put_status(:bad_request)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render("400.json", %{error: :invalid_request, message: "must supply either cursor id or page number"})
  end

  def perform(conn, filters) do
    {employees, count} = Employee.list_employees_with_paging(filters)

    conn
    |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_employee.json", data: employees)
  end

  defmodule View do
    def render("list_employee.json", %{data: employees}) do
      Enum.map(employees, &%{
        id: &1.id,
        name: &1.name,
        phone: &1.phone,
        removed_datetime: &1.removed_datetime,
        inserted_at: &1.inserted_at,
        updated_at: &1.updated_at
      })
    end
  end
end
