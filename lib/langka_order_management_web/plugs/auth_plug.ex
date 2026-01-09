defmodule LangkaOrderManagementWeb.AuthPlug do
  import Plug.Conn

  alias LangkaOrderManagement.{Jwt, Repo, Account.User}

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer" <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{"sub" => user_id} = claims} <- Jwt.verify(token),
         %User{} = user <- Repo.get(User, user_id) do
          conn
          |> put_private(:current_claim, claims)
          |> put_private(:user_context, user)
         else
          _ ->
            conn
            |> put_private(:user_context, nil)
            |> put_private(:current_claim, nil)
         end
  end
end
