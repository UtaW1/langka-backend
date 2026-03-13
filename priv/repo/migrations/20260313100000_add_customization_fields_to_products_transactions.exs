defmodule LangkaOrderManagement.Repo.Migrations.AddCustomizationFieldsToProductsTransactions do
  use Ecto.Migration

  def change do
    alter table(:products_transactions) do
      add :sugar_level, :integer
      add :ice_level, :string
      add :order_note, :text
    end
  end
end
