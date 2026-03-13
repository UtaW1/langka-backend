defmodule LangkaOrderManagement.SeatingTable.SeatingTable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seating_tables" do
    field :table_number, :string
    field :seating_count, :integer

    has_many :transactions, LangkaOrderManagement.Account.Transaction

    timestamps()
  end

  def changeset(table, attrs) do
    table
    |> cast(attrs, [:table_number, :seating_count])
    |> validate_required([:table_number, :seating_count])
    |> validate_number(:seating_count, greater_than_or_equal_to: 1)
  end
end
