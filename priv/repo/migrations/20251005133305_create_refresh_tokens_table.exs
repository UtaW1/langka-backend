defmodule LangkaOrderManagement.Repo.Migrations.CreateRefreshTokensTable do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token_hash, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :last_used_at, :utc_datetime

      add :revoked_datetime, :utc_datetime
      add :session_id, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(updated_at: false)
    end

    create index(:refresh_tokens, [:user_id, :session_id])
  end
end
