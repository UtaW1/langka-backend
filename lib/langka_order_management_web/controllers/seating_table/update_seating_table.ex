defmodule LangkaOrderManagementWeb.UpdateSeatingTable do
  alias LangkaOrderManagement.SeatingTable

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer],
      "table_number" => [required: false, nullable: true, type: :string],
      "seating_count" => [required: false, nullable: true, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, %{"id" => id} = args) do
    with table when not is_nil(table) <- SeatingTable.get_seating_table(id),
         {:ok, updated_table} <- SeatingTable.update_seating_table(table, args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_seating_table.json", data: updated_table)
    else
      nil ->
        ControllerUtils.render_error(conn, 422, "422.json", :seating_table_not_found, "")

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
    def render("update_seating_table.json", %{data: table}) do
      %{
        id: table.id,
        table_number: table.table_number,
        seating_count: table.seating_count,
        inserted_at: table.inserted_at
      }
    end
  end
end
