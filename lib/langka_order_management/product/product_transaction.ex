defmodule LangkaOrderManagement.Product.ProductTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Product.Product
  alias LangkaOrderManagement.Account.Transaction

  schema "products_transactions" do
    belongs_to :product, Product
    belongs_to :transaction, Transaction, type: :binary_id

    field :quantity, :integer, default: 1
    field :sugar_level, :integer
    field :ice_level, :string
    field :order_note, :string

    timestamps(updated_at: false)
  end

  def changeset(product_transaction, attrs) do
    product_transaction
    |> cast(attrs, [:product_id, :transaction_id, :quantity, :sugar_level, :ice_level, :order_note])
    |> validate_required([:product_id, :transaction_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 1)
    |> validate_inclusion(:sugar_level, [0, 25, 50, 75, 100, 125])
    |> validate_inclusion(:ice_level, ["no ice", "less ice", "normal ice"])
  end

end
