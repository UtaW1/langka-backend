defmodule LangkaOrderManagementWeb.RequireAuth do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(%{private: %{user_context: nil}} = conn, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "unauthorized"})
    |> halt()
  end

  def call(conn, _opts), do: conn
end
