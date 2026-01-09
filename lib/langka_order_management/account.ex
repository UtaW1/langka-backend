defmodule LangkaOrderManagement.Account do
  @moduledoc """
  Account context, holds account fuctionality
  """

  alias LangkaOrderManagement.{Repo, Account.User}
  import Ecto.Query

  def get_user_by_id(id) do
    User
    |> where([u], u.id == ^id)
    |> Repo.one()
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
