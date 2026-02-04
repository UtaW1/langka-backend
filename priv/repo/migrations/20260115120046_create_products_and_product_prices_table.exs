defmodule LangkaOrderManagement.Repo.Migrations.CreateProductsAndProductPricesTable do
  use Ecto.Migration

  def change do
    create table(:product_categories) do
      add :name, :string
      add :description, :string

      timestamps()
    end

    create table(:products) do
      add :name, :string
      add :removed_datetime, :utc_datetime
      add :code, :string

      add :product_category_id, references(:product_categories, on_delete: :nothing), null: false

      timestamps()
    end

    create table(:product_prices) do
      add :price_as_usd, :decimal

      add :product_id, references(:products, on_delete: :nothing), null: false
      timestamps(updated_at: false)
    end

    create index(:product_prices, [:product_id])
    create index(:products, [:product_category_id])
  end
end
