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
  def render("400.json", %{error: error, message: err_msg})
      when is_atom(error) and is_binary(err_msg) do
    %{
      message: error,
      detail: err_msg
    }
  end

  def render("401.json", %{error: "" <> err_msg}) do
    %{
      message: err_msg,
      detail: nil
    }
  end

  def render("401.json", %{error: {error_key, "" <> err_msg}}) when is_atom(error_key) do
    %{
      message: error_key,
      detail: err_msg
    }
  end

  def render("422.json", %{error: "" <> err_msg}) do
    %{
      message: err_msg,
      detail: nil
    }
  end

  def render("422.json", %{error: %Ecto.Changeset{} = cs}) do
    %{
      message: "changeset validation error",
      detail: format_changeset_error(cs.errors)
    }
  end

  def render("422.json", %{error: {error_key, "" <> err_msg}}) when is_atom(error_key) do
    %{
      message: error_key,
      detail: err_msg
    }
  end

  def render("422.json", %{error: error}) when is_atom(error) do
    %{
      message: "",
      detail: error
    }
  end

  def render("500.json", %{error: error}) do
    %{
      message: "",
      detail: "#{inspect(error)}"
    }
  end

  def render("500.json", error) do
    %{
      message: "Unexpected Error Occured",
      detail: "#{inspect(error)}"
    }
  end

  def render("404.json", _assigns) do
    %{
      message: "Route Not Found",
      detail: "The route you are trying to access does not exist."
    }
  end

  def render(_, %{error: {error_key, err_msg}}) do
    %{
      message: error_key,
      detail: err_msg
    }
  end

  def render(_, %{error: error}) do
    %{
      message: "",
      detail: "#{inspect(error)}"
    }
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  defp format_changeset_error(errors) when is_list(errors) do
    for {field, {message, _metadata}} <- errors, into: %{} do
      {field, message}
    end
  end
end
