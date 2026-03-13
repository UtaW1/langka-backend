defmodule LangkaOrderManagementWeb.CreateSeatingTable do
  alias LangkaOrderManagement.SeatingTable

  def rules(_) do
    %{
      "table_number" => [required: true, nullable: false, type: :string],
      "seating_count" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, args) do
    with {:ok, table} <- SeatingTable.create_seating_table(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_seating_table.json", data: table)
    else
      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("400.json", %{error: :changeset_error, message: "changeset error #{inspect(changeset)}"})
    end
  end

  defmodule View do
    def render("create_seating_table.json", %{data: table}) do
      %{
        id: table.id,
        table_number: table.table_number,
        seating_count: table.seating_count
      }
    end
  end
end
