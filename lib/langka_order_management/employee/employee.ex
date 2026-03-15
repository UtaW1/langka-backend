defmodule LangkaOrderManagement.Employee.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "employees" do
    field :name, :string
    field :phone, :string
    field :removed_datetime, :utc_datetime

    timestamps()
  end

  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:name, :phone, :removed_datetime])
    |> validate_required([:name, :phone])
  end
end
