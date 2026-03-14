defmodule LangkaOrderManagement.Promotion do
  import Ecto.Query, warn: false
  alias LangkaOrderManagement.{Repo, ContextUtil}

  alias LangkaOrderManagement.{
    Promotion.Promotion,
    Promotion.UserPromotionTracker,
    Account.Transaction
  }
  def get_promotion!(id), do: Repo.get!(Promotion, id)
  def create_promotion(attrs \\ %{}) do
    %Promotion{}
    |> Promotion.changeset(attrs)
    |> Repo.insert()
  end

  def get_promotion(id), do: Repo.get(Promotion, id)

  def update_promotion(%Promotion{} = promotion, args) do
    promotion
    |> Promotion.changeset(args)
    |> Repo.update()
  end

  def get_a_user_latest_continous_promotion_for_transaction(user_id) do
    UserPromotionTracker
    |> where([upt], upt.user_id == ^user_id)
    |> where([upt], not upt.used_up)
    |> order_by(desc: :id)
    |> limit(1)
    |> preload([upt], :promotion)
    |> Repo.one()
  end

  def get_user_progression_on_promotion(user_id, promo_id) do
    UserPromotionTracker
    |> where([upt], upt.user_id == ^user_id)
    |> where([upt], upt.promotion_id == ^promo_id)
    |> preload([upt], :promotion)
    |> Repo.one()
  end

  def determine_promotion_apply(user_id) do
    continous_promotion = get_a_user_latest_continous_promotion_for_transaction(user_id)

    case continous_promotion do
      %UserPromotionTracker{promotion: %Promotion{} = promotion, transaction_count: transaction_count} ->
        if transaction_count >= promotion.transaction_count_to_get_discount do
          promotion
        else
          nil
        end

      _ ->
        nil
    end
  end

  def promotion_used?(promotion_id) do
    Transaction
    |> where([t], t.status == ^"completed")
    |> where([t], t.promotion_apply_id == ^promotion_id)
    |> Repo.exists?()
  end

  def retire_promotion(%Promotion{status: "active"} = promotion) do
    promotion
    |> Promotion.retire_changeset(%{status: "retired", removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update()
  end

  def retire_promotion(_), do: {:error, :promotion_in_unactive_state}

  def list_promotions_with_paging(filters) do
    promotion_query =
      Promotion
      |> from(as: :promotion)
      |> ContextUtil.list(filters)

    {
      promotion_query
      |> exclude(:order_by)
      |> order_by([p], desc: :id)
      |> Repo.all(),

      promotion_query
      |> exclude(:limit)
      |> exclude(:offset)
      |> exclude(:order_by)
      |> select([p], count())
      |> Repo.one()
    }
  end

  def get_latest_active_promotion_for_transaction() do
    Promotion
    |> where([p], p.status == ^"active")
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end
end
