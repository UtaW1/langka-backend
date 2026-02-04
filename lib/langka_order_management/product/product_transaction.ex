defmodule LangkaOrderManagement.Product.ProductTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Product.Product
  alias LangkaOrderManagement.Account.Transaction

  schema "products_transactions" do
    belongs_to :product, Product
    belongs_to :transaction, Transaction, type: :binary_id

    field :quantity, :integer, default: 1

    timestamps(updated_at: false)
  end

  def changeset(product_transaction, attrs) do
    product_transaction
    |> cast(attrs, [:product_id, :transaction_id])
    |> validate_required([:product_id, :transaction_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 1)
  end

end
