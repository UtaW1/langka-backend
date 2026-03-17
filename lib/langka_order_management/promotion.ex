defmodule LangkaOrderManagement.Promotion do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias LangkaOrderManagement.{Repo, ContextUtil}

  alias LangkaOrderManagement.{
    Promotion.Promotion,
    Promotion.UserPromotionTracker,
    Account.Transaction
  }
  def get_promotion!(id), do: Repo.get!(Promotion, id)
  def create_promotion(attrs \\ %{}) do
    attrs = Map.put_new(attrs, "status", "active")

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
    |> join(:inner, [upt], p in assoc(upt, :promotion))
    |> where([_upt, p], p.status == ^"active")
    |> order_by(asc: :id)
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
    case resolve_promotion_for_transaction(user_id) do
      %{promotion_apply: promotion} ->
        promotion

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
    Multi.new()
    |> Multi.update(
      :promotion,
      Promotion.retire_changeset(promotion, %{status: "retired", removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)})
    )
    |> Multi.delete_all(
      :retired_progression_trackers,
      from(upt in UserPromotionTracker,
        where: upt.promotion_id == ^promotion.id and not upt.used_up
      )
    )
    |> Repo.transact()
    |> case do
      {:ok, %{promotion: retired_promotion}} -> {:ok, retired_promotion}
      {:error, :promotion, reason, _changes} -> {:error, reason}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
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

  def resolve_promotion_for_transaction(user_id) do
    cleanup_retired_progressions_for_user(user_id)

    latest_active_promotion = get_latest_active_promotion_for_transaction()
    current_progression = get_a_user_latest_continous_promotion_for_transaction(user_id)

    case {current_progression, latest_active_promotion} do
      {nil, nil} ->
        %{promotion_apply: nil, promotion_tracker_args: nil}

      {nil, %Promotion{} = latest} ->
        %{
          promotion_apply: nil,
          promotion_tracker_args: %{
            transaction_count: 1,
            used_up: false,
            user_id: user_id,
            promotion_id: latest.id
          }
        }

      {%UserPromotionTracker{promotion: %Promotion{} = promotion, transaction_count: transaction_count}, _latest} ->
        if transaction_count >= promotion.transaction_count_to_get_discount do
          %{
            promotion_apply: promotion,
            promotion_tracker_args: %{
              transaction_count: transaction_count,
              used_up: true,
              user_id: user_id,
              promotion_id: promotion.id
            }
          }
        else
          %{
            promotion_apply: nil,
            promotion_tracker_args: %{
              transaction_count: transaction_count + 1,
              used_up: false,
              user_id: user_id,
              promotion_id: promotion.id
            }
          }
        end

      _ ->
        nil
    end
  end

  def preview_next_order_discount(nil) do
    latest_active_promotion = get_latest_active_promotion_for_transaction()

    case latest_active_promotion do
      nil ->
        %{
          will_have_discount_on_next_order: false,
          current_progress_count: 0,
          required_transaction_count: nil,
          remaining_orders_before_discount: nil,
          promotion: nil
        }

      %Promotion{} = promotion ->
        %{
          will_have_discount_on_next_order: false,
          current_progress_count: 0,
          required_transaction_count: promotion.transaction_count_to_get_discount,
          remaining_orders_before_discount: promotion.transaction_count_to_get_discount,
          promotion: promotion
        }
    end
  end

  def preview_next_order_discount(user_id) do
    latest_active_promotion = get_latest_active_promotion_for_transaction()
    current_progression = get_a_user_latest_continous_promotion_for_transaction(user_id)

    case {current_progression, latest_active_promotion} do
      {nil, nil} ->
        %{
          will_have_discount_on_next_order: false,
          current_progress_count: 0,
          required_transaction_count: nil,
          remaining_orders_before_discount: nil,
          promotion: nil
        }

      {nil, %Promotion{} = promotion} ->
        %{
          will_have_discount_on_next_order: false,
          current_progress_count: 0,
          required_transaction_count: promotion.transaction_count_to_get_discount,
          remaining_orders_before_discount: promotion.transaction_count_to_get_discount,
          promotion: promotion
        }

      {%UserPromotionTracker{promotion: %Promotion{} = promotion, transaction_count: transaction_count}, _latest} ->
        remaining = max(promotion.transaction_count_to_get_discount - transaction_count, 0)

        %{
          will_have_discount_on_next_order: transaction_count >= promotion.transaction_count_to_get_discount,
          current_progress_count: transaction_count,
          required_transaction_count: promotion.transaction_count_to_get_discount,
          remaining_orders_before_discount: remaining,
          promotion: promotion
        }
    end
  end

  defp cleanup_retired_progressions_for_user(user_id) do
    from(upt in UserPromotionTracker,
      join: p in assoc(upt, :promotion),
      where: upt.user_id == ^user_id,
      where: p.status != ^"active",
      where: not upt.used_up
    )
    |> Repo.delete_all()

    :ok
  end
end
