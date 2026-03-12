defmodule LangkaOrderManagementWeb.GetProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with product when not is_nil(product) <- Product.get_enriched_product_by_id(id)
      do
        conn
        |> Phoenix.Controller.put_view(__MODULE__.View)
        |> Phoenix.Controller.render("get_product.json", data: product)
      else
        nil ->
          ControllerUtils.render_error(conn, 404, "404.json", "product not found", "")
    end
  end

  defmodule View do
    def render("get_product.json", %{data: product}) do
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
