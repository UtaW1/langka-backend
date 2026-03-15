defmodule LangkaOrderManagement.Inventory.Inventory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventories" do
    field :name, :string
    field :note, :string
    field :removed_datetime, :utc_datetime

    has_many :movements, LangkaOrderManagement.Inventory.InventoryMovement

    timestamps()
  end

  def changeset(inventory, attrs) do
    inventory
    |> cast(attrs, [:name, :note, :removed_datetime])
    |> validate_required([:name])
  end
end
