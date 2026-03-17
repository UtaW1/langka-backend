defmodule LangkaOrderManagementWeb.ListProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "label" => [required: false, nullable: true, type: :string],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 32}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "ids_in" => [nullable: true, required: false, list: [required: false, nullable: true, cast: :integer, type: :integer, min: 1]],
      "ids_not_in" => [nullable: true, required: false, list: [required: false, nullable: true, cast: :integer, type: :integer, min: 1]],
      "is_removed" => [required: false, nullable: true, cast: :string, type: :string, in: ["yes", "no"]],
      "is_load_latest_price" => [required: false, nullable: true, custom: &ControllerUtils.validate_boolean/1],
      "category_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, %{"cursor_id" => "" <> _, "page_number" => page_number}) when not is_nil(page_number) do
    conn
    |> Plug.Conn.put_status(:bad_request)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render("400.json", %{error: :invalid_request, message: "cannot supply both cursor_id and page_number"})
  end

  def perform(conn, %{"cursor_id" => cursor_id, "page_number" => page_number}) when is_nil(page_number) and is_nil(cursor_id) do
    conn
    |> Plug.Conn.put_status(:bad_request)
    |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
    |> Phoenix.Controller.render("400.json", %{error: :invalid_request, message: "must supply either cursor id or page number"})
  end

  def perform(conn, filters) do
    with {products, total_count} <- Product.list_products_with_paging(filters) do
      conn
      |> Plug.Conn.put_resp_header("x-paging-total-count", "#{total_count}")
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("list_product.json", data: products)
    end
  end

  defmodule View do
    def render("list_product.json", %{data: products}) do
      Enum.map(products, &%{
        id: &1.product.id,
        name: &1.product.name,
        code: &1.product.code,
        inserted_at: &1.product.inserted_at,
        image_url: &1.product.image_url,
        removed_datetime: &1.product.removed_datetime,
        categories: %{
          id: &1.product.product_category.id,
          name: &1.product.product_category.name,
          updated_at: &1.product.product_category.updated_at,
          inserted_at: &1.product.product_category.inserted_at,
        },
        latest_price: %{
          id: &1.latest_product_price.id,
          price_as_usd: &1.latest_product_price.price_as_usd,
          inserted_at: &1.latest_product_price.inserted_at
        }
      })
    end
  end
end
