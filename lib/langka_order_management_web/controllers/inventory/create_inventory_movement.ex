defmodule LangkaOrderManagementWeb.CreateInventoryMovement do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "inventory_id" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1],
      "movement_type" => [required: true, nullable: false, custom: &validate_movement_type/1],
      "quantity" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, args) do
    with {:ok, %{movement: movement, actual_quantity: actual_quantity}} <- Inventory.create_inventory_movement(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_inventory_movement.json", data: {movement, actual_quantity})
    else
      {:error, :inventory, :inventory_not_found, _} ->
        ControllerUtils.render_error(conn, 404, "404.json", :inventory_not_found, "")

      {:error, :validate_quantity, :insufficient_stock, _} ->
        ControllerUtils.render_error(conn, 422, "422.json", :insufficient_stock, "not enough stock for this out movement")

      {:error, :movement, %Ecto.Changeset{} = changeset, _} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})

      {:error, :invalid_params} ->
        ControllerUtils.render_error(conn, 422, "422.json", :invalid_params, "invalid movement params")

      err ->
        ControllerUtils.render_error(conn, 500, "500.json", :unexpected_error, "#{inspect(err)}")
    end
  end

  defmodule View do
    def render("create_inventory_movement.json", %{data: {movement, actual_quantity}}) do
      %{
        id: movement.id,
        inventory_id: movement.inventory_id,
        movement_type: movement.movement_type,
        quantity: movement.quantity,
        actual_quantity: actual_quantity,
        inserted_at: movement.inserted_at,
        updated_at: movement.updated_at
      }
    end
  end

  defp validate_movement_type(%{value: "in"}), do: Validate.Validator.success("in")
  defp validate_movement_type(%{value: "out"}), do: Validate.Validator.success("out")
  defp validate_movement_type(%{value: _}), do: Validate.Validator.error("movement_type must be in or out")
end
