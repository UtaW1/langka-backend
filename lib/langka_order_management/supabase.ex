defmodule LangkaOrderManagement.Supabase do
  def supabase_server_url() do
    :langka_order_management
    |> Application.get_env(:supabase)
    |> Keyword.get(:server_url)
  end

  def supabase_api_token() do
    :langka_order_management
    |> Application.get_env(:supabase)
    |> Keyword.get(:api_key)
  end

  def http_client() do
    middlewares = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 16_000},
      {Tesla.Middleware.BaseUrl, "#{supabase_server_url()}/storage/v1"},
      {
        Tesla.Middleware.Headers,
        [
          {
            "apiKey",
            supabase_api_token()
          },
          {
            "authorization",
            "Bearer #{supabase_api_token()}"
          }
        ]
      }
    ]

    Tesla.client(middlewares)
  end

  defp create_bucket(client, bucket_name) do
    body = %{
      "name" => bucket_name,
      "public" => false
    }

    case Tesla.post(client, "/bucket", body) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, client}

      err ->
        {:error, :supabase_error, {err}}
    end
  end

  defp ensure_bucket_exists(client, bucket_name) do
    case Tesla.get(client, "/bucket/#{bucket_name}") do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, client}

      {:ok, %Tesla.Env{body: %{"statusCode" => "404"}}} ->
        create_bucket(client, bucket_name)
    end
  end

  defp try_upload_as_new_file({:ok, client}, {bucket_name, file_data, file_path}) do
    encoded_path = URI.encode(file_path)

    case Tesla.post(client, "/object/#{bucket_name}/#{encoded_path}", file_data) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "supabase-s3:#{bucket_name}:#{file_path}"}

      {:ok, %Tesla.Env{status: 400, body: %{"error" => "Duplicate"}}} ->
        {:error, :duplicate, {client, bucket_name, file_path, file_data}}
    end
  end

  defp try_upload_as_new_file(pass, _), do: pass

  defp replace_file_if_exist({:error, :duplicate, {client, bucket_name, file_path, file_data}}) do
    case Tesla.put(client, "/object/#{bucket_name}/#{file_path}", file_data) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "supabase-s3:#{bucket_name}:#{file_path}"}

      {:ok, %Tesla.Env{status: _status, body: %{"statusCode" => status} = body}} ->
        {:error, {:supabase_error, "error with status - #{status}", "#{inspect(body)}"}}
    end
  end

  defp replace_file_if_exist({:ok, "supabase-s3:" <> _} = pass), do: pass

  def upload(bucket_name, file_data, file_path) do
    http_client()
    |> ensure_bucket_exists(bucket_name)
    |> try_upload_as_new_file({bucket_name, file_data, file_path})
    |> replace_file_if_exist()
  end

  def get_download_url(req) do
    body = %{
      "expiresIn" => 120
    }

    case Tesla.post(http_client(), "/object/sign/#{req.bucket_name}/#{req.file_path}", body) do
      {:ok, %Tesla.Env{status: 200, body: %{"signedURL" => download_url}}} ->
        {:ok, "#{supabase_server_url()}/storage/v1#{download_url}"}

      {:ok, %Tesla.Env{status: _status, body: %{"statusCode" => status_code}}} ->
        {:error, status_code}

      {:error, reason} ->
        {:error, "failed to sign the object: #{inspect(reason)}"}
    end
  end

  def remove(bucket_name, file_path) do
    case Tesla.delete(http_client(), "/object/#{bucket_name}/#{file_path}") do
      {:ok, %Tesla.Env{status: 200, body: %{"message" => "Successfully deleted"}}} ->
        {:ok, nil}

      {:ok, %Tesla.Env{status: 404, body: %{"message" => "Object not found"}}} ->
        {:ok, :object_not_found}

      err ->
        {:error, err}
    end
  end

  def get_public_asset(%{image_transform: image_transform} = req) do
    base_url = get_base_url(http_client())
    url = "#{base_url}/object/public/#{req.bucket_name}/#{req.file_path}"

    transformation = Enum.map_join(apply_image_transform_option(image_transform), "&", fn {k, v} -> "#{k}=#{v}" end)

    transformed_url =
      if transformation == "" do
        url
      else
        "#{url}?#{transformation}"
      end

    case Tesla.get(http_client(), transformed_url) do
      {:ok, %Tesla.Env{status: 200, body: body}} when is_binary(body) ->
        {:ok, transformed_url}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :not_found, "file not found"}

      {:ok, %Tesla.Env{status: _status, body: %{"statusCode" => status_code}}} ->
        {:error, :unexpected_response, status_code}

      {:error, reason} ->
        {:error, :unexpected_error, "failed to get file: #{inspect(reason)}"}
    end
  end

  defp get_base_url(http_client) do
    case Enum.find(http_client.pre, fn
      {Tesla.Middleware.BaseUrl, :call, [_base_url]} -> true
      _ -> false
    end) do
      {Tesla.Middleware.BaseUrl, :call, [base_url]} -> base_url
      _ -> raise "Base URL not found in tesla client"
    end
  end

  defp apply_image_transform_option(%{} = image_transform) do
    %{
      "resize" => "cover",
      "format" => "avif",
      "width" => image_transform.width,
      "height" => image_transform.height,
      "quality" => image_transform.quality
    }
  end

  defp apply_image_transform_option(_), do: %{}
end
