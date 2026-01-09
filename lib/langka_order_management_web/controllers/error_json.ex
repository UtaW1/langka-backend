defmodule LangkaOrderManagementWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".

  def render("422.json", %{error: "" <> err_msg}) do
    %{
      message: err_msg,
      detail: nil
    }
  end

  def render("422.json", %{error: {error_key, "" <> error_message}}) when is_atom(error_key) do
    %{
      message: error_message,
      detail: error_key
    }
  end

  def render("422.json", %{error: error}) when is_atom(error) do
    %{
      message: "",
      detail: error
    }
  end

  def render("422.json", %{error: %Ecto.Changeset{errors: errors}}) do
    %{
      message: "",
      detail: Enum.map(errors, &%{attribute: elem(&1, 0), error: &1 |> elem(1) |> elem(0)})
    }
  end

  def render("401.json", %{error: error}) when is_atom(error) do
    %{
      message: "invalid credentails",
      detail: error
    }
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
