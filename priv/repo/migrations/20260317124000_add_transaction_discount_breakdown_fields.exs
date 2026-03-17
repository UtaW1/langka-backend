defmodule LangkaOrderManagement.Repo.Migrations.AddTransactionDiscountBreakdownFields do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :bill_price_before_discount_as_usd, :decimal
      add :bill_price_after_discount_as_usd, :decimal
      add :discount_amount_as_usd, :decimal
      add :discount_as_percent_applied, :decimal
    end
  end
end
