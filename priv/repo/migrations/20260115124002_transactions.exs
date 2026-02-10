defmodule LangkaOrderManagement.Repo.Migrations.Transactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, default: "pending", null: false
      add :invoice_id, :string
      add :bill_price_as_usd, :decimal

      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
    end

    create table(:products_transactions) do
      add :product_id, references(:products, on_delete: :nothing), null: false
      add :transaction_id, references(:transactions, type: :binary_id, on_delete: :nothing), null: false
      add :quantity, :integer, default: 1

      timestamps(updated_at: false)
    end

    create index(:transactions, [:user_id])
    create unique_index(:products_transactions, [:product_id, :transaction_id])
  end
end
