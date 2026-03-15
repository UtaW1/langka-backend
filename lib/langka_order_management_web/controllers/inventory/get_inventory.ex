defmodule LangkaOrderManagementWeb.GetInventory do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with %{inventory: inventory, actual_quantity: actual_quantity} <- Inventory.get_inventory_with_actual_quantity(id),
         true <- not is_nil(inventory) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("get_inventory.json", data: {inventory, actual_quantity})
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "inventory not found", "")

      false ->
        ControllerUtils.render_error(conn, 404, "404.json", "inventory not found", "")
    end
  end

  defmodule View do
    def render("get_inventory.json", %{data: {inventory, actual_quantity}}) do
      %{
        id: inventory.id,
        name: inventory.name,
        note: inventory.note,
        image_url: inventory.image_url,
        removed_datetime: inventory.removed_datetime,
        actual_quantity: actual_quantity,
        inserted_at: inventory.inserted_at,
        updated_at: inventory.updated_at
      }
    end
  end
end
