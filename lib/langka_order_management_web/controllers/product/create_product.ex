defmodule LangkaOrderManagementWeb.CreateProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "name" => [required: true, nullable: false, type: :string, cast: :string],
      "code" => [required: false, nullable: true, type: :string],
      "product_category_id" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1],
      "price_as_usd" => [required: true, nullable: false, cast: :float, type: :float, min: 0.1],
      "product_image" => [required: false, custom: &ControllerUtils.validate_images/1]
    }
  end

  def perform(conn, args) do
    with {:ok, product} when not is_nil(product) <- Product.create_product(args),
         args <- Map.put(args, "product_id", product.id),
         {:ok, product_price} when not is_nil(product_price) <- Product.create_product_price(args),
         {:ok, updated_product} <- Product.upload_product_image(args["product_image"], product)
    do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_product.json", data: {updated_product, product_price})
    else
      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("400.json", %{error: :changeset_error, message: "changeset error #{inspect(changeset)}"})
    end
  end

  defmodule View do
    def render("create_product.json", %{data: {product, product_price}}) do
      %{
        id: product.id,
        name: product.name,
        code: product.code,
        image_url: product.image_url,
        product_price: %{
          id: product_price.id,
          price_as_usd: product_price.price_as_usd
        }
      }
    end
  end
end
