defmodule LangkaOrderManagement.Account.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Account.User
  alias LangkaOrderManagement.Promotion.Promotion
  alias LangkaOrderManagement.Product.{ProductTransaction}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "transactions" do
    field :status, :string, default: "pending"
    field :invoice_id, :string
    field :bill_price_as_usd, :decimal

    belongs_to :user, User, type: :binary_id
    belongs_to :seating_table, LangkaOrderManagement.SeatingTable.SeatingTable
    belongs_to :promotion_apply, Promotion

    has_many :product_transactions, ProductTransaction
    has_many :products, through: [:product_transactions, :product]

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:status, :invoice_id, :bill_price_as_usd, :user_id, :seating_table_id, :promotion_apply_id])
    |> validate_required([:status, :bill_price_as_usd, :seating_table_id])
    |> validate_number(:bill_price_as_usd, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, ["pending", "cancelled"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:promotion_apply_id)
  end

  def succsesful_transaction_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:status])
    |> validate_inclusion(:status, ["completed"])
  end

  def cancel_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:status])
    |> validate_inclusion(:status, ["cancelled"])
  end

  def update_invoice_id_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:invoice_id])
    |> validate_required([:invoice_id])
  end
end
