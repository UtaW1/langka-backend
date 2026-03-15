defmodule LangkaOrderManagementWeb.DeleteInventory do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with inventory when not is_nil(inventory) <- Inventory.get_inventory(id),
         {:ok, _} <- Inventory.delete_inventory(inventory) do
      Plug.Conn.send_resp(conn, 204, "")
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "inventory not found", "")

      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})
    end
  end
end
