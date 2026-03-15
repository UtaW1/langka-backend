defmodule LangkaOrderManagement.Repo.Migrations.AddInventoryMovementIndexes do
  use Ecto.Migration

  def change do
    create index(:inventory_movements, [:inventory_id])
    create index(:inventory_movements, [:inventory_id, :movement_type])
    create index(:inventory_movements, [:inventory_id, :inserted_at])
  end
end
