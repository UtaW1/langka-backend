defmodule LangkaOrderManagementWeb.ListInventoryMovement do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "inventory_id" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1],
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 64}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "movement_type" => [required: false, nullable: true, custom: &validate_movement_type/1]
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

  def perform(conn, %{"inventory_id" => inventory_id} = filters) do
    with inventory when not is_nil(inventory) <- Inventory.get_inventory(inventory_id) do
      {movements, count} = Inventory.list_inventory_movements_with_paging(filters)
      actual_quantity = Inventory.get_actual_quantity(inventory_id)

      conn
      |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("list_inventory_movement.json", data: %{movements: movements, actual_quantity: actual_quantity})
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "inventory not found", "")
    end
  end

  defmodule View do
    def render("list_inventory_movement.json", %{data: %{movements: movements, actual_quantity: actual_quantity}}) do
      %{
        actual_quantity: actual_quantity,
        movements: Enum.map(movements, fn movement ->
          %{
            id: movement.id,
            inventory_id: movement.inventory_id,
            movement_type: movement.movement_type,
            quantity: movement.quantity,
            inserted_at: movement.inserted_at,
            updated_at: movement.updated_at
          }
        end)
      }
    end
  end

  defp validate_movement_type(%{value: nil}), do: Validate.Validator.success(nil)
  defp validate_movement_type(%{value: "in"}), do: Validate.Validator.success("in")
  defp validate_movement_type(%{value: "out"}), do: Validate.Validator.success("out")
  defp validate_movement_type(%{value: _}), do: Validate.Validator.error("movement_type must be in or out")
end
