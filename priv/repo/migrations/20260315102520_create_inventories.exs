defmodule LangkaOrderManagement.Repo.Migrations.CreateInventories do
  use Ecto.Migration

  def change do
    create table(:inventories) do
      add :name, :string
      add :note, :string
      add :removed_datetime, :utc_datetime

      timestamps()
    end

    create table(:inventory_movements) do
      add :inventory_id, references(:inventories, on_delete: :nothing), null: false
      add :movement_type, :string
      add :quantity, :integer

      timestamps()
    end
  end
end
