defmodule LangkaOrderManagement.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :name, :string
      add :phone, :string
      add :removed_datetime, :utc_datetime

      timestamps()
    end
  end
end
