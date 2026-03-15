defmodule LangkaOrderManagement.Inventory.InventoryMovement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_movements" do
    field :movement_type, :string
    field :quantity, :integer

    belongs_to :inventory, LangkaOrderManagement.Inventory.Inventory

    timestamps()
  end

  def changeset(movement, attrs) do
    movement
    |> cast(attrs, [:movement_type, :quantity, :inventory_id])
    |> validate_required([:movement_type, :quantity, :inventory_id])
    |> validate_inclusion(:movement_type, ["in", "out"])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:inventory_id)
  end
end
