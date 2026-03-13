defmodule LangkaOrderManagementWeb.GetSeatingTable do
  alias LangkaOrderManagement.SeatingTable

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with table when not is_nil(table) <- SeatingTable.get_seating_table(id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("get_seating_table.json", data: table)
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "seating table not found", "")
    end
  end

  defmodule View do
    def render("get_seating_table.json", %{data: table}) do
      %{
        id: table.id,
        table_number: table.table_number,
        seating_count: table.seating_count
      }
    end
  end
end
