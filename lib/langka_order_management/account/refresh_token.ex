defmodule LangkaOrderManagement.Account.RefreshToken do
  @moduledoc "refresh token schema"
  use Ecto.Schema
  import Ecto.Changeset

  alias LangkaOrderManagement.Account.User

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "refresh_tokens" do
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :last_used_at, :utc_datetime
    field :revoked_datetime, :utc_datetime

    field :session_id, :string

    belongs_to :user, User, type: :binary_id

    timestamps(updated_at: false)
  end

  def changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:token_hash, :expires_at, :user_id, :session_id])
    |> validate_required([:token_hash, :expires_at, :user_id, :session_id])
    |> foreign_key_constraint(:user_id)
  end

  def revoke_changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:revoked_datetime])
    |> validate_required([:revoked_datetime])
  end

  def used_changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:last_used_at])
    |> validate_required([:last_used_at])
  end
end
