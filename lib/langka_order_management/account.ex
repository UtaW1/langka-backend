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
    Product.ProductTransaction,
    ContextUtil
  }
  import Ecto.Query

  def list_all_transactions(filters) do
    query =
      Transaction
      |> where([t], t.status == ^"completed")
      |> ContextUtil.list(filters)
      |> preload([t], [product_transactions: :product, seating_table: []])

    transactions = Repo.all(query)

    count =
      query
      |> exclude(:select)
      |> exclude(:order_by)
      |> exclude(:preload)
      |> select([t], count(t.id))
      |> Repo.one()

    {transactions, count}
  end

  def list_all_users(filters) do
    query =
      User
      |> where([u], u.role == ^"customer")
      |> ContextUtil.list(filters)

    users = Repo.all(query)

    count =
      query
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([u], count(u.id))
      |> Repo.one()

    {users, count}
  end

  def list_transactions_for_export(args) do
    Transaction
    |> where([t], t.status == ^"completed")
    |> where([t], type(t.inserted_at, :date) >= ^args["start_date"] and type(t.inserted_at, :date) <= ^args["end_date"])
    |> preload([t], :products)
    |> Repo.all()
    |> Enum.map(& %{
      id: &1.id,
      price: &1.bill_price_as_usd,
      user_id: &1.user_id,
      promotion_id: &1.promotion_apply_id
    })
  end

  def get_user_by_id(id) do
    User
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_transaction_by_id(id) do
    Transaction
    |> where([t], t.id == ^id)
    |> preload([t], [:employee, product_transactions: :product, seating_table: []])
    |> Repo.one()
  end

  def assign_employee_to_transaction(%Transaction{status: "pending", employee_id: nil} = transaction, employee_id)
      when is_integer(employee_id) do
    transaction
    |> Transaction.assign_employee_changeset(%{employee_id: employee_id})
    |> Repo.update()
  end

  def assign_employee_to_transaction(%Transaction{status: "pending", employee_id: employee_id} = transaction, employee_id)
      when is_integer(employee_id) do
    {:ok, transaction}
  end

  def assign_employee_to_transaction(%Transaction{status: "pending", employee_id: _existing}, _employee_id),
    do: {:error, :transaction_already_assigned}

  def assign_employee_to_transaction(_transaction, _employee_id),
    do: {:error, :transaction_in_non_processable_state}

  def complete_order_on_webhook_callback(%Transaction{status: "pending"} = transaction) do
    transaction
    |> Transaction.succsesful_transaction_changeset(%{status: "completed"})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, :employee)}
      error -> error
    end
  end

  def complete_order_on_webhook_callback(_), do: {:error, :transaction_in_non_processable_state}

  def cancel_order_on_webhook_callback(%Transaction{status: "pending"} = transaction) do
    transaction
    |> Transaction.cancel_changeset(%{status: "cancelled"})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, :employee)}
      error -> error
    end
  end

  def cancel_order_on_webhook_callback(_), do: {:error, :transaction_in_non_processable_state}

  def update_completed_transaction_invoice_id(transaction_id, invoice_id) do
    transaction =
      Transaction
      |> where([t], t.id == ^transaction_id)
      |> where([t], t.status == ^"completed")
      |> Repo.one()

    case transaction do
      %Transaction{} = transaction ->
        transaction
        |> Transaction.update_invoice_id_changeset(%{invoice_id: invoice_id})
        |> Repo.update()

      nil ->
        {:error, :transaction_not_found_or_not_completed}
    end
  end

  def make_pending_order(%{"user_id" => nil} = args) do
    make_pending_order(Map.drop(args, ["user_id"]))
  end

  def make_pending_order(%{"name" => name, "phone_number" => phone_number} = args) do
    products_orders = args["products_orders"]

    with {:ok, %User{} = user} <- get_or_create_user(name, phone_number) do
      user_id = user.id

      promotion_apply = Promotion.determine_promotion_apply(user_id)
      latest_promo = Promotion.get_latest_active_promotion_for_transaction()
      user_lastest_continous_promo = Promotion.get_a_user_latest_continous_promotion_for_transaction(user_id)

      {final_price, enriched_products_orders, _discount_amount} = Payment.calculate_final_price(products_orders, promotion_apply)

      promotion_tracker =
        case {promotion_apply, user_lastest_continous_promo, latest_promo} do
          {%Promotion.Promotion{}, %UserPromotionTracker{}, _} ->
            %{
              transaction_count: user_lastest_continous_promo.transaction_count,
              used_up: true,
              user_id: user_id,
              promotion_id: user_lastest_continous_promo.promotion_id
            }

          {nil, nil, %Promotion.Promotion{}} ->
            %{
              transaction_count: 1,
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

      transaction_args = %{
        status: "pending",
        invoice_id: args["invoice_id"],
        seating_table_id: args["seating_table_id"],
        bill_price_as_usd: final_price,
        user_id: user_id,
        promotion_apply_id: if(promotion_apply, do: promotion_apply.id, else: nil)
      }

      Ecto.Multi.new()
      |> Ecto.Multi.put(:products_orders, enriched_products_orders)
      |> Ecto.Multi.put(:promotion_tracker_args, promotion_tracker)
      |> Ecto.Multi.insert(:pending_transaction, Transaction.changeset(%Transaction{}, transaction_args))
      |> Ecto.Multi.insert_all(:transaction_product, ProductTransaction, fn %{pending_transaction: transaction} ->
        build_products_transaction_rows(products_orders, transaction.id)
      end)
      |> Ecto.Multi.run(:user_promotion_tracker, fn repo, %{promotion_tracker_args: tracker_args} ->
        if is_map(tracker_args) do
          %UserPromotionTracker{}
          |> UserPromotionTracker.changeset(tracker_args)
          |> repo.insert(
            on_conflict: [set: [transaction_count: tracker_args.transaction_count, used_up: tracker_args.used_up]],
            conflict_target: [:promotion_id, :user_id]
          )
        else
          {:ok, :skipped}
        end
      end)
      |> Repo.transact()
    end
  end

  defp get_or_create_user(name, phone_number) do
    existing_user =
      User
      |> where([u], u.phone_number == ^phone_number)
      |> Repo.one()

    case existing_user do
      %User{} = user ->
        {:ok, user}

      nil ->
        case register_user(%{
               "username" => name,
               "phone_number" => phone_number,
               "role" => "customer"
             }) do
          {:ok, %User{} = user} ->
            {:ok, user}

          {:error, _changeset} ->
            user =
              User
              |> where([u], u.phone_number == ^phone_number)
              |> Repo.one()

            if user do
              {:ok, user}
            else
              {:error, :failed_to_create_or_find_user}
            end
        end
    end
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
        if is_binary(user.hashed_password) and Argon2.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end
    end
  end

  defp build_products_transaction_rows(products_orders, transaction_id) do
    inserted_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Enum.map(products_orders, fn product_order ->
      %{
        product_id: get_order_value(product_order, "product_id"),
        transaction_id: transaction_id,
        quantity: get_order_value(product_order, "quantity"),
        sugar_level: get_order_value(product_order, "sugar_level"),
        ice_level: get_order_value(product_order, "ice_level"),
        order_note: get_order_value(product_order, "order_note"),
        inserted_at: inserted_at
      }
    end)
  end

  defp get_order_value(product_order, key) do
    case Map.fetch(product_order, key) do
      {:ok, value} ->
        value

      :error ->
        Map.get(product_order, String.to_atom(key))
    end
  end
end
