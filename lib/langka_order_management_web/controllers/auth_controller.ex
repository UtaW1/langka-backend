defmodule LangkaOrderManagementWeb.AuthController do
  use LangkaOrderManagementWeb, :controller

  alias LangkaOrderManagement.{
    Account,
    Account.User,
    Auth,
    Repo
  }
  alias LangkaOrderManagementWeb.{ErrorJSON}

  import Plug.Conn

  action_fallback LangkaOrderManagementWeb.ActionFallback

  def register(conn, args) do
    changeset = User.registration_changeset(%User{}, args)

    case Repo.insert(changeset) do
      {:ok, user} ->
        set_auth_cookies_and_respond(conn, user)

      {:error, changeset} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          :unprocessable_entity,
          "422.json"
          |> ErrorJSON.render(%{error: changeset})
          |> Jason.encode!()
        )
    end
  end

  def login(conn, %{"phone_number" => phone_number, "password" => password}) do
    case Account.authenticate_user(phone_number, password) do
      {:ok, %User{} = user} ->
        set_auth_cookies_and_respond(conn, user)

      {:error, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          :unauthorized,
          "401.json"
          |> ErrorJSON.render(%{error: :invalid_credentials})
          |> Jason.encode!()
        )
    end
  end

  def refresh(%{private: %{user_context: %User{} = user}} = conn, %{"csrf_token" => csrf_token_from_request}) do
    csrf_cookie = conn.req_cookies["refresh_csrf"]
    refresh_token = conn.req_cookies["refresh_token"]
    session_id = conn.req_cookies["session_id"]

    cond do
      csrf_cookie == nil or csrf_token_from_request != csrf_cookie ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          :forbidden,
          "403.json"
          |> ErrorJSON.render(%{error: {:forbidden, "validation failed"}})
          |> Jason.encode!()
        )

      refresh_token == nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          :unauthorized,
          "401.json"
          |> ErrorJSON.render(%{error: {:unauthorized, "no refresh token"}})
          |> Jason.encode!()
        )

      true ->
        case Auth.verify_and_consume_refresh_token(user, refresh_token, session_id) do
          {:ok, new_refresh_token} ->
            access_token = Auth.generate_access_token_after_consume_refresh_token(user)

            conn
            |> put_refresh_token_cookie(new_refresh_token)
            |> put_csrf_cookie()
            |> json(%{access_token: access_token})

          {:error, :invalid} ->
            conn
            |> delete_resp_cookie("refresh_token")
            |> delete_resp_cookie("refresh_csrf")
            |> delete_resp_cookie("session_id")
            |> put_resp_content_type("application/json")
            |> send_resp(
              :unauthorized,
              "401.json"
              |> ErrorJSON.render(%{error: {:unauthorized, "invalid token"}})
              |> Jason.encode!()
            )

        end
    end
  end

  def logout(%{private: %{user_context: %User{} = user}} = conn, _) do
    session_id = conn.req_cookies["session_id"]

    Auth.revoke_session(session_id, user)

    conn
    |> delete_resp_cookie("refresh_token")
    |> delete_resp_cookie("refresh_csrf")
    |> delete_resp_cookie("session_id")
    |> send_resp(:no_content, "")
  end

  defp set_auth_cookies_and_respond(conn, user) do
    session_id = Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

    {access_token, refresh_token} = Auth.issue_tokens(user, session_id)

    conn
    |> put_session_id_cookie(session_id)
    |> put_refresh_token_cookie(refresh_token)
    |> put_csrf_cookie()
    |> json(%{access_token: access_token, user_id: user.id, role: user.role})
  end

  defp put_session_id_cookie(conn, session_id) do
    put_resp_cookie(conn, "session_id", session_id,
      http_only: true,
      secure: true,
      same_site: "Lax",
      max_age: 60 * 60 * 24 * 30
    )
  end

  defp put_refresh_token_cookie(conn, token) do
    put_resp_cookie(conn, "refresh_token", token,
      http_only: true,
      secure: true,
      same_site: "Lax",
      max_age: 60 * 60 * 24 * 30
    )
  end

  defp put_csrf_cookie(conn) do
    csrf = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

    put_resp_cookie(conn, "refresh_csrf", csrf,
      http_only: false,
      secure: true,
      same_site: "Lax",
      max_age: 60 * 60 * 24 * 30
    )
  end
end
