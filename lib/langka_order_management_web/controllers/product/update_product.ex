defmodule LangkaOrderManagementWeb.UpdateProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer],
      "name" => [required: false, nullable: true, type: :string, cast: :string],
      "code" => [required: false, nullable: true, type: :string],
      "price_as_usd" => [required: false, nullable: true, cast: :float, type: :float, min: 0.1],
      "product_image" => [required: false, custom: &ControllerUtils.validate_images/1]
    }
  end

  def perform(conn, %{"id" => id, "product_image" => nil} = args) do
    with product when not is_nil(product) <- Product.get_product(id),
         {:ok, updated_product} <- Product.update_product(product, args)
      do
        conn
        |> Phoenix.Controller.put_view(__MODULE__.View)
        |> Phoenix.Controller.render("update_product.json", data: updated_product)
      else
        nil ->
          ControllerUtils.render_error(conn, 422, "422.json", :product_not_found, "")
        err ->
          ControllerUtils.render_error(conn, 500, "500.json", :unexpected_error, "#{inspect(err)}")
    end
  end

  def perform(conn, %{"id" => id, "product_image" => %Plug.Upload{} = image} = args) do
    with product = %Product.Product{} <- Product.get_product(id),
         {:ok, _} <- Product.delete_product_image(product),
         {:ok, updated_product} <- Product.update_product(product, args),
         {:ok, updated_image} <- Product.upload_product_image(image, updated_product)
    do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_product.json", data: updated_image)
    else
      nil ->
        ControllerUtils.render_error(conn, 422, "422.json", :product_not_found, "")

      err ->
        err
    end
  end

  defmodule View do
    @moduledoc false
    def render("update_product.json", %{data: product}) do
      %{
        id: product.id,
        name: product.name,
        code: product.code,
        image_url: product.image_url,
        product_price: %{
          id: product.latest_product_price.id,
          price_as_usd: product.latest_product_price.price_as_usd
        }
      }
    end
  end
end
