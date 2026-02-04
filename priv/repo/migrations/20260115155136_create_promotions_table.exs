defmodule LangkaOrderManagement.Repo.Migrations.CreatePromotionsTable do
  use Ecto.Migration

  def change do
    create table(:promotions) do
      add :transaction_count_to_get_discount, :integer
      add :discount_as_percent, :decimal
      add :status, :string
      add :removed_datetime, :utc_datetime

      timestamps(updated: false)
    end

    alter table(:transactions) do
      add :promotion_apply_id, references(:promotions, on_delete: :nothing)
    end
  end
end
