defmodule LangkaOrderManagement.Inventory do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias LangkaOrderManagement.{ContextUtil, Repo, Supabase}
  alias LangkaOrderManagement.Inventory.{Inventory, InventoryMovement}

  @bucketname "inventory-images"

  def list_inventories_with_paging(filters) do
    base_query =
      Inventory
      |> ContextUtil.list(filters)

    movement_totals = movement_totals_query()

    inventories =
      base_query
      |> join(:left, [inventory], movement in subquery(movement_totals),
        on: movement.inventory_id == inventory.id,
        as: :movement
      )
      |> select([inventory, movement: movement], %{
        inventory: inventory,
        actual_quantity: fragment("COALESCE(?, 0)", movement.actual_quantity)
      })
      |> Repo.all()

    count =
      base_query
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([inventory], count(inventory.id))
      |> Repo.one()

    {inventories, count}
  end

  def get_inventory(id), do: Repo.get(Inventory, id)

  def get_inventory_with_actual_quantity(id) do
    movement_totals = movement_totals_query()

    Inventory
    |> where([inventory], inventory.id == ^id)
    |> join(:left, [inventory], movement in subquery(movement_totals), on: movement.inventory_id == inventory.id)
    |> select([inventory, movement], %{
      inventory: inventory,
      actual_quantity: fragment("COALESCE(?, 0)", movement.actual_quantity)
    })
    |> Repo.one()
  end

  def get_actual_quantity(inventory_id) do
    InventoryMovement
    |> where([movement], movement.inventory_id == ^inventory_id)
    |> select([movement],
      fragment(
        "COALESCE(SUM(CASE WHEN ? = 'in' THEN ? ELSE -? END), 0)",
        movement.movement_type,
        movement.quantity,
        movement.quantity
      )
    )
    |> Repo.one()
  end

  def create_inventory(attrs) do
    %Inventory{}
    |> Inventory.changeset(attrs)
    |> Repo.insert()
  end

  def delete_inventory_image(%Inventory{image_url: "" <> url}) do
    encoded_url = URI.encode(url)

    case Supabase.remove(@bucketname, encoded_url) do
      {:ok, nil} ->
        {:ok, nil}

      err ->
        err
    end
  end

  def delete_inventory_image(_), do: {:ok, nil}

  def update_inventory(%Inventory{} = inventory, attrs) do
    inventory
    |> Inventory.changeset(attrs)
    |> Repo.update()
  end

  def delete_inventory(%Inventory{} = inventory) do
    inventory
    |> Inventory.changeset(%{removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update()
  end

  def create_inventory_movement(%{"inventory_id" => inventory_id, "movement_type" => movement_type, "quantity" => quantity} = attrs)
      when movement_type in ["in", "out"] and is_integer(quantity) and quantity > 0 do
    Multi.new()
    |> Multi.run(:inventory, fn repo, _ ->
      inventory =
        Inventory
        |> where([inventory], inventory.id == ^inventory_id)
        |> where([inventory], is_nil(inventory.removed_datetime))
        |> lock("FOR UPDATE")
        |> repo.one()

      if inventory do
        {:ok, inventory}
      else
        {:error, :inventory_not_found}
      end
    end)
    |> Multi.run(:current_quantity, fn repo, %{inventory: inventory} ->
      quantity =
        InventoryMovement
        |> where([movement], movement.inventory_id == ^inventory.id)
        |> select([movement],
          fragment(
            "COALESCE(SUM(CASE WHEN ? = 'in' THEN ? ELSE -? END), 0)",
            movement.movement_type,
            movement.quantity,
            movement.quantity
          )
        )
        |> repo.one()

      {:ok, quantity}
    end)
    |> Multi.run(:validate_quantity, fn _repo, %{current_quantity: current_quantity} ->
      case movement_type do
        "out" when quantity > current_quantity ->
          {:error, :insufficient_stock}

        _ ->
          {:ok, :validated}
      end
    end)
    |> Multi.insert(:movement, InventoryMovement.changeset(%InventoryMovement{}, attrs))
    |> Multi.run(:actual_quantity, fn _repo, %{current_quantity: current_quantity} ->
      delta = if movement_type == "in", do: quantity, else: -quantity

      {:ok, current_quantity + delta}
    end)
    |> Repo.transact()
  end

  def create_inventory_movement(_), do: {:error, :invalid_params}

  def upload_inventory_image(%Plug.Upload{path: tmp_path, content_type: content_type}, %Inventory{name: name, id: id} = inventory) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.slice(0..18)
      |> String.replace(~r/[^0-9]/, "")

    normalized_name = String.replace(name, " ", "-")

    filename = "inventory-#{id}-#{normalized_name}:#{Nanoid.generate(32)}:#{timestamp}"

    content_type =
      content_type
      |> String.split("/")
      |> List.last()

    file_path = "inventory/#{filename}.#{content_type}"

    encoded_file_path = URI.encode(file_path)

    tmp_path = File.read!(tmp_path)

    case Supabase.upload(@bucketname, tmp_path, encoded_file_path) do
      {:ok, _} ->
        inventory
        |> Inventory.changeset(%{image_url: file_path})
        |> Repo.update()

      {:error, reason} ->
        {:error, %{upload_error: reason}}
    end
  end

  def upload_inventory_image(_, %Inventory{} = inventory), do: {:ok, inventory}

  def list_inventory_movements_with_paging(%{"inventory_id" => inventory_id} = filters) do
    query =
      InventoryMovement
      |> where([movement], movement.inventory_id == ^inventory_id)
      |> maybe_filter_movement_type(filters)
      |> ContextUtil.list(filters)

    movements = Repo.all(query)

    count =
      query
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([movement], count(movement.id))
      |> Repo.one()

    {movements, count}
  end

  def list_inventory_movements_with_paging(_), do: {[], 0}

  defp movement_totals_query do
    InventoryMovement
    |> group_by([movement], movement.inventory_id)
    |> select([movement], %{
      inventory_id: movement.inventory_id,
      actual_quantity:
        fragment(
          "COALESCE(SUM(CASE WHEN ? = 'in' THEN ? ELSE -? END), 0)",
          movement.movement_type,
          movement.quantity,
          movement.quantity
        )
    })
  end

  defp maybe_filter_movement_type(query, %{"movement_type" => movement_type}) when movement_type in ["in", "out"] do
    where(query, [movement], movement.movement_type == ^movement_type)
  end

  defp maybe_filter_movement_type(query, _), do: query
end
