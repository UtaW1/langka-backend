defmodule LangkaOrderManagement.Product.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Product.{ProductCategory, ProductPrice}

  schema "products" do
    field :latest_product_price, :map, virtual: true

    field :name, :string
    field :removed_datetime, :utc_datetime
    field :code, :string

    belongs_to :product_category, ProductCategory

    has_many :prices, ProductPrice

    has_many :product_transactions, LangkaOrderManagement.Product.ProductTransaction
    has_many :transactions, through: [:product_transactions, :transaction]

    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :code, :product_category_id, :removed_datetime])
    |> validate_required([:name, :product_category_id])
    |> foreign_key_constraint(:product_category_id)
  end
end
