defmodule LangkaOrderManagement.Account do
  @moduledoc """
  Account context, holds account fuctionality
  """

  alias LangkaOrderManagement.{
    Repo,
    Account.User,
    Promotion,
    Promotion.UserPromotionTracker,
    Payment,
    Account.Transaction,
    Product.ProductTransaction
  }
  import Ecto.Query

  def get_user_by_id(id) do
    User
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_transaction_by_id(id) do
    Transaction
    |> where([t], t.id == ^id)
    |> Repo.one()
  end

  def complete_order_on_webhook_callback(%Transaction{status: "pending"} = transaction) do
    transaction
    |> Transaction.succsesful_transaction_changeset(%{status: "completed"})
    |> Repo.update()
  end

  def complete_order_on_webhook_callback(_), do: {:error, :transaction_in_non_processable_state}

  def cancel_order_on_webhook_callback(%Transaction{status: "pending"} = transaction) do
    transaction
    |> Transaction.cancel_changeset(%{status: "cancelled"})
    |> Repo.update()
  end

  def cancel_order_on_webhook_callback(_), do: {:error, :transaction_in_non_processable_state}

  def make_pending_order(%{"user_id" => nil} = args) do
    products_orders = args["products_orders"]

    {final_price, enriched_products_orders, _discount_amount} = Payment.calculate_final_price(products_orders, nil)

    args = %{
      status: :pending,
      invoice_id: args["invoice_id"],
      bill_price_as_usd: final_price,
      user_id: nil,
      promotion_apply_id: nil
    }

    Ecto.Multi.new()
    |> Ecto.Multi.put(:products_orders, enriched_products_orders)
    |> Ecto.Multi.insert(:pending_transaction, Transaction.changeset(%Transaction{}, args))
    |> Ecto.Multi.insert_all(:transaction_product, ProductTransaction, fn %{pending_transaction: transaction} ->
      Enum.map(products_orders, & %{
        product_id: &1.product_id,
        transaction_id: transaction.id,
        quantity: &1.quantity
      })
    end)
    |> Repo.transact()
  end

  def make_pending_order(%{"user_id" => user_id} = args) do
    products_orders = args["products_orders"]

    promotion_apply = Promotion.determine_promotion_apply(user_id)

    latest_promo = Promotion.get_latest_active_promotion_for_transaction()

    user_lastest_continous_promo = Promotion.get_a_user_latest_continous_promotion_for_transaction(user_id)

    {final_price, enriched_products_orders, _discount_amount} = Payment.calculate_final_price(products_orders, promotion_apply)

    promotion_tracker =
      case {promotion_apply, user_lastest_continous_promo, latest_promo} do
        {nil, nil, %Promotion.Promotion{}} ->
          %{
            transaction_count: 0,
            used_up: false,
            user_id: user_id,
            promotion_id: latest_promo.id
          }

        {nil, %UserPromotionTracker{}, _} ->
          %{
            transaction_count: user_lastest_continous_promo.transaction_count + 1,
            used_up: false,
            user_id: user_id,
            promotion_id: user_lastest_continous_promo.promotion_id
          }

        _ ->
          nil
      end

    args = %{
      status: :pending,
      invoice_id: args["invoice_id"],
      bill_price_as_usd: final_price,
      user_id: user_id,
      promotion_apply_id:
        if promotion_apply do
          promotion_apply.id
        else
          nil
        end
    }

    Ecto.Multi.new()
    |> Ecto.Multi.put(:products_orders, enriched_products_orders)
    |> Ecto.Multi.put(:promotion_tracker_args, promotion_tracker)
    |> Ecto.Multi.insert(:pending_transaction, Transaction.changeset(%Transaction{}, args))
    |> Ecto.Multi.insert_all(:transaction_product, ProductTransaction, fn %{pending_transaction: transaction} ->
      Enum.map(products_orders, & %{
        product_id: &1.product_id,
        transaction_id: transaction.id,
        quantity: &1.quantity
      })
    end)
    |> Ecto.Multi.run(:user_promotion_tracker, fn repo, %{promotion_tracker_args: args} ->
      if is_map(args) do
        %UserPromotionTracker{}
        |> UserPromotionTracker.changeset(args)
        |> repo.insert(
          on_conflict: [set: [transaction_count: args.transaction_count]],
          conflict_target: [:promotion_id, :user_id]
        )
      else
        {:ok, :skipped}
      end
    end)
    |> Repo.transact()
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(phone_number, password) do
    user =
      User
      |> where([u], u.phone_number == ^phone_number)
      |> Repo.one()

    case user do
      nil ->
        {:error, :unauthorized}

      %User{} ->
        if Argon2.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end
    end
  end
end
