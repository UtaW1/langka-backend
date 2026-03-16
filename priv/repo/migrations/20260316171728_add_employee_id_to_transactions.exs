defmodule LangkaOrderManagement.Repo.Migrations.AddEmployeeIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :employee_id, references(:employees, on_delete: :nothing)
    end

    create index(:transactions, [:employee_id])
  end
end
