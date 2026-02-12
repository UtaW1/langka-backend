defmodule LangkaOrderManagementWeb.ControllerUtils do
  alias LangkaOrderManagement.Supabase

  def render_error(conn, status, render, error, message) do
    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.put_view(EpicureCanteenWeb.ErrorJSON)
    |> Phoenix.Controller.render(render, error: error, message: message)
  end

  def validate_boolean(%{value: nil}), do: Validate.Validator.success(nil)
  def validate_boolean(%{value: "true"}), do: Validate.Validator.success(true)
  def validate_boolean(%{value: true}), do: Validate.Validator.success(true)
  def validate_boolean(%{value: "false"}), do: Validate.Validator.success(false)
  def validate_boolean(%{value: false}), do: Validate.Validator.success(false)
  def validate_boolean(%{value: _}) , do: Validate.Validator.error("value must be true or false")

  def upload_to_storage_and_get_url(content, bucket_name, dir) do
    case Supabase.upload(bucket_name, content, dir) do
      {:ok, _} ->
        Supabase.get_download_url(%{file_path: dir, bucket_name: bucket_name})

      {:error, reason} ->
        {:error, reason}
    end
  end
end
