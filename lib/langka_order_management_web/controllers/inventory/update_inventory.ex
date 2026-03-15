defmodule LangkaOrderManagementWeb.UpdateInventory do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer],
      "name" => [required: false, nullable: true, type: :string],
      "note" => [required: false, nullable: true, type: :string]
    }
  end

  def perform(conn, %{"id" => id} = args) do
    with inventory when not is_nil(inventory) <- Inventory.get_inventory(id),
         {:ok, _updated_inventory} <- Inventory.update_inventory(inventory, args),
         %{inventory: latest_inventory, actual_quantity: actual_quantity} <- Inventory.get_inventory_with_actual_quantity(id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_inventory.json", data: {latest_inventory, actual_quantity})
    else
      nil ->
        ControllerUtils.render_error(conn, 422, "422.json", :inventory_not_found, "")

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
    def render("update_inventory.json", %{data: {inventory, actual_quantity}}) do
      %{
        id: inventory.id,
        name: inventory.name,
        note: inventory.note,
        removed_datetime: inventory.removed_datetime,
        actual_quantity: actual_quantity,
        inserted_at: inventory.inserted_at,
        updated_at: inventory.updated_at
      }
    end
  end
end
