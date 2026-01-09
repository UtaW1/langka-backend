defmodule LangkaOrderManagementWeb.ActionFallback do
  @moduledoc false

  use Phoenix.Controller

  def call(conn, {:error, %Ecto.Changeset{} = cs}) do
    conn
    |> put_status(:unprocessable_entity)
    |> setup_error_view(cs)
  end

  def call(conn, {:error, error}) when is_atom(error) do
    conn
    |> put_status(:unprocessable_entity)
    |> setup_error_view(error)
  end

  def call(conn, {:error, {error_key, "" <> err_msg, _context}}) when is_atom(error_key) do
    conn
    |> put_status(:unprocessable_entity)
    |> setup_error_view({error_key, err_msg})
  end

  def setup_error_view(conn, error) do
    conn
    |> put_view(json: LangkaOrderManagementWeb.ErrorJSON)
    |> render(:"#{conn.status}", error: error)
  end
end
