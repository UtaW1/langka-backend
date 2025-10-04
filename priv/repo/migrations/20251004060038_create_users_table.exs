defmodule LangkaOrderManagement.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :phone_number, :string
      add :hashed_password, :string, null: false
      add :role, :string, null: false, default: "user"

      timestamps()
    end
  end
end
