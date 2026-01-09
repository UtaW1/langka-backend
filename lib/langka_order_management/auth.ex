defmodule LangkaOrderManagement.Auth do
  @moduledoc false

  alias LangkaOrderManagement.{
    Repo,
    Jwt,
    Account.RefreshToken
  }

  import Ecto.Query

  @token_expires_30_days DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
  @token_expires_20_minutes_unix DateTime.utc_now() |> DateTime.add(1200, :second) |> DateTime.to_unix()

  def generate_refresh_token(user, session_id) do
    raw = Base.url_encode64(:crypto.strong_rand_bytes(64), padding: false)
    token_hash = Base.encode16(:crypto.hash(:sha256, raw), case: :lower)

    %RefreshToken{}
    |> RefreshToken.changeset(%{
      user_id: user.id,
      token_hash: token_hash,
      session_id: session_id,
      expires_at: @token_expires_30_days,
    })
    |> Repo.insert!()

    {:ok, raw}
  end

  def revoke_session(session_id, user) do
    RefreshToken
    |> where([rt], rt.session_id == ^session_id)
    |> where([rt], rt.user_id == ^user.id)
    |> Repo.update_all(set: [revoked_datetime: DateTime.utc_now()])
  end

  def verify_and_consume_refresh_token(user, refresh_token, session_id) do
    hashed_token = Base.encode16(:crypto.hash(:sha256, refresh_token), case: :lower)

    token_query =
      RefreshToken
      |> where([rt], rt.user_id == ^user.id)
      |> where([rt], is_nil(rt.revoked_datetime))
      |> where([rt], rt.expires_at > ^DateTime.utc_now())
      |> where([rt], rt.token_hash == ^hashed_token)
      |> where([rt], rt.session_id == ^session_id)
      |> Repo.one()

    case token_query do
      nil ->
        {:error, :invalid}

      %RefreshToken{} ->
        token_query
          |> RefreshToken.used_changeset(%{last_used_at: DateTime.utc_now()})
          |> Repo.update!

        generate_refresh_token(user, session_id)
    end
  end

  def refresh_token_used?(user, refresh_token) do
    hashed_token = Base.encode16(:crypto.hash(:sha256, refresh_token), case: :lower)

    RefreshToken
    |> where([rt], rt.user_id == ^user.id)
    |> where([rt], not is_nil(rt.last_used_at))
    |> where([rt], rt.token_hash == ^hashed_token)
    |> Repo.exists?()
  end

  def issue_tokens(user, session_id) do
    claims = %{
      "sub" => user.id,
      "exp" => @token_expires_20_minutes_unix,
      "role" => user.role
    }

    access_token = Jwt.signs(claims)

    {:ok, refresh_token} = generate_refresh_token(user, session_id)

    {access_token, refresh_token}
  end

  def generate_access_token_after_consume_refresh_token(user) do
    claims = %{
      "sub" => user.id,
      "exp" => @token_expires_20_minutes_unix,
      "role" => user.role
    }

    Jwt.signs(claims)
  end

end
