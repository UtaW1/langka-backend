defmodule LangkaOrderManagement.Repo.Migrations.CreateServingTableTable do
  use Ecto.Migration

  def change do
    create table(:seating_tables) do
      add :table_number, :string
      add :seating_count, :integer

      timestamps()
    end

    alter table(:transactions) do
      add :seating_table_id, references(:seating_tables, on_delete: :nothing)

      remove :table_number, :string
    end

    create index(:transactions, [:seating_table_id])
  end
end
