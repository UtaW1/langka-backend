defmodule LangkaOrderManagementWeb.ControllerUtils do
  alias LangkaOrderManagement.Supabase

  def validate_phone_number(%{value: nil}), do: Validate.Validator.success(nil)

  def validate_phone_number(%{value: "" <> phone}) do
    case normalize_kh_phone(phone) do
      {:ok, normalized} ->
        Validate.Validator.success(normalized)

      {:error, msg} ->
        Validate.Validator.error(msg)
    end
  end

  def validate_phone_number(%{value: _}), do: Validate.Validator.error("value must be a non-empty string")

  defp normalize_kh_phone(phone) when is_binary(phone) do
    digits = String.replace(phone, ~r/[^0-9]/, "")

    cond do
      String.starts_with?(digits, "855") and valid_kh_length?(digits, 3) ->
        {:ok, "+#{digits}"}

      String.starts_with?(digits, "0") and valid_kh_length?(digits, 0) ->
        {:ok, "+855" <> String.slice(digits, 1..-1//1)}

      valid_kh_length?(digits, 0) ->
        {:ok, "+855" <> digits}

      true ->
        {:error, "invalid phone number"}
    end
  end

  defp normalize_kh_phone(_phone), do: {:error, "phone number must be a string"}

  defp valid_kh_length?(digits, prefix_len) do
    len = String.length(digits) - prefix_len

    len in [8, 9, 10]
  end

  def render_error(conn, status, render, "" <> err_msg) do
    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render(render, %{error: err_msg})
  end

  def render_error(conn, status, render, %{} = err) do
    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render(render, %{error: err})
  end

  def render_error(conn, status, render, error, message) do
    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render(render, %{error: {error, message}})
  end

  def validate_boolean(%{value: nil}), do: Validate.Validator.success(nil)
  def validate_boolean(%{value: "true"}), do: Validate.Validator.success(true)
  def validate_boolean(%{value: true}), do: Validate.Validator.success(true)
  def validate_boolean(%{value: "false"}), do: Validate.Validator.success(false)
  def validate_boolean(%{value: false}), do: Validate.Validator.success(false)
  def validate_boolean(%{value: _}) , do: Validate.Validator.error("value must be true or false")

  def validate_iso8601_datetime(%{value: nil}),
    do: Validate.Validator.success(nil)

  def validate_iso8601_datetime(%{value: "" <> datetime}) do
    case DateTime.from_iso8601(datetime) do
      {:ok, datetime, _} ->
        Validate.Validator.success(datetime)

      {:error, :invalid_format} ->
        Validate.Validator.error("datetime has to be in iso8601 format, eg: 2024-06-09T16:06:09.128Z")
    end
  end

  def validate_images(%{value: images}) when map_size(images) > 0 do
    if valid_image?(images) do
      Validate.Validator.success(images)
    else
      Validate.Validator.error("file must be a valid image type (jpeg/png/webp only)")
    end
  end

  def validate_images(%{value: images}) when is_list(images) do
    if Enum.all?(images, &valid_image?/1) do
      Validate.Validator.success(images)
    else
      Validate.Validator.error("each file must be a valid image type (jpeg/png/webp only)")
    end
  end

  def validate_images(%{value: nil}), do: Validate.Validator.success(nil)

  defp valid_image?(%Plug.Upload{content_type: content_type, path: path}) do
    content_type in ["image/jpeg", "image/png", "image/webp"] and File.exists?(path)
  end

  defp valid_image?(_), do: false

  def upload_to_storage_and_get_url(content, bucket_name, dir) do
    case Supabase.upload(bucket_name, content, dir) do
      {:ok, _} ->
        Supabase.get_download_url(%{file_path: dir, bucket_name: bucket_name})

      {:error, reason} ->
        {:error, reason}
    end
  end
end
