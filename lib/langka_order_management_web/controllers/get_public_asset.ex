defmodule LangkaOrderManagementWeb.GetPublicAsset do
  alias LangkaOrderManagement.{Supabase}

  @bucketname ["product-images", "inventory-images"]

  def rules(_) do
    %{
      "image_url" => [required: true, nullable: false, cast: :string, type: :string],
      "image_transform" => [required: false, nullable: true, type: :map],
      "bucket_name" => [required: true, nullable: false, type: :string, in: @bucketname]
    }
  end

  def perform(conn, args) do
    args = %{
      file_path: args["image_url"],
      image_transform: args["image_transform"],
      bucket_name: args["bucket_name"]
    }

    with {:ok, download_url} <- Supabase.get_public_asset(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("get_product_image.json", data: download_url)
    else
      err ->
        LangkaOrderManagementWeb.ControllerUtils.render_error(conn, 500, "500.json", %{error: err})
    end
  end

  defmodule View do
    def render("get_product_image.json", %{data: url}) do
      %{
        download_url: url
      }
    end
  end
end
