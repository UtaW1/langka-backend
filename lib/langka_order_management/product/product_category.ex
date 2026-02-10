defmodule LangkaOrderManagement.Product.ProductCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Product.Product

  schema "product_categories" do
    field :name, :string
    field :description, :string

    has_many :products, Product

    field :removed_datetime, :utc_datetime
    field :removed_reason, :string

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
