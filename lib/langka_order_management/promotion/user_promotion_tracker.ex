defmodule LangkaOrderManagement.Promotion.UserPromotionTracker do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.{
    Account.User,
    Promotion.Promotion
  }

  schema "user_promotions_tracker" do
    field :transaction_count, :integer, default: 0
    field :used_up, :boolean, default: false

    belongs_to :user, User, type: :binary_id
    belongs_to :promotion, Promotion
  end

  def changeset(user_promotion_tracker, attrs) do
    user_promotion_tracker
    |> cast(attrs, [:transaction_count, :used_up, :user_id, :promotion_id])
    |> validate_required([:user_id, :promotion_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:promotion_id)
    |> unique_constraint([:promotion_id, :user_id])
  end

  def update_count_changeset(user_promotion_tracker, attrs) do
    user_promotion_tracker
    |> cast(attrs, [:transaction_count, :used_up])
    |> validate_required([:transaction_count])
    |> validate_number(:transaction_count, greater_than_or_equal_to: 0)
  end
end
