defmodule LangkaOrderManagement.Repo.Migrations.AddTimestampsToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :table_number, :string, null: false
      timestamps()
    end
  end
end
