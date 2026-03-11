defmodule LangkaOrderManagement.Account.User do
  @moduledoc "user schema"

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :username, :string
    field :phone_number, :string
    field :hashed_password, :string
    field :role, :string, default: "user"

    field :password, :string, virtual: true

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :phone_number, :password, :role])
    |> validate_exclusion(:role, ["admin"])
    |> validate_required([:username, :password])
    |> validate_length(:password, min: 8)
    |> put_hashed_password()
  end

  defp put_hashed_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    change(cs, hashed_password: Argon2.hash_pwd_salt(pw))
  end

  defp put_hashed_password(cs), do: cs
end
