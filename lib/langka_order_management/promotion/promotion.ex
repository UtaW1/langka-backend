defmodule LangkaOrderManagement.Promotion.Promotion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "promotions" do
    field :transaction_count_to_get_discount, :integer
    field :discount_as_percent, :decimal
    field :status, :string
    field :removed_datetime, :utc_datetime

    timestamps()
  end

  def changeset(promotion, attrs) do
    promotion
    |> cast(attrs, [:transaction_count_to_get_discount, :discount_as_percent, :status, :removed_datetime])
    |> validate_required([:transaction_count_to_get_discount, :discount_as_percent])
    |> validate_number(:transaction_count_to_get_discount, greater_than_or_equal_to: 1)
    |> validate_number(:discount_as_percent, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, ["active", "retired"])
  end

  def retire_changeset(promotion, attrs) do
    promotion
    |> cast(attrs, [:status, :removed_datetime])
    |> validate_inclusion(:status, ["retired"])
  end
end
