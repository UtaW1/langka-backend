defmodule LangkaOrderManagement.Repo.Migrations.CreateUserPromotionTracker do
  use Ecto.Migration

  def change do
    create table(:user_promotions_tracker) do
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :promotion_id, references(:promotions, on_delete: :nothing), null: false
      add :transaction_count, :integer, default: 0
      add :used_up, :boolean, default: false

      timestamps()
    end

    create unique_index(:user_promotions_tracker, [:user_id, :promotion_id])
  end
end
