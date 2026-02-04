defmodule LangkaOrderManagement.Product.ProductPrice do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Product.Product

  schema "product_prices" do
    field :price_as_usd, :decimal

    belongs_to :product, Product

    timestamps()
  end

  def changeset(product_price, attrs) do
    product_price
    |> cast(attrs, [:price_as_usd, :product_id])
    |> validate_required([:price_as_usd, :product_id])
    |> validate_number(:price_as_usd, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:product_id)
  end
end
