defmodule LangkaOrderManagementWeb.FormRequest do
  use Validate.Plugs.FormRequest,
    validate_success: :validate_success,
    validate_error: :validate_error,
    auth_error: :auth_error

  import Plug.Conn

  def validate_success(conn, data) do
    assign(conn, :validated, data)
  end

  def validate_error(conn, errors) do
    error_map = Validate.Util.errors_to_map(errors)
    conn
    |> put_status(422)
    |> Phoenix.Controller.json(%{
        message: "",
        errors: error_map
      })
    |> halt()
  end

  def auth_error(conn) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{
        message: "unauthorized",
        errors: %{detail: nil}
      })
    |> halt()
  end
end
