defmodule LangkaOrderManagementWeb.ListProductCategory do
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
      "is_removed" => [required: false, nullable: true, custom: &ControllerUtils.validate_boolean/1],
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
    with {product_categories, count} <- Product.list_product_categories_with_paging(filters) do
      conn
      |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("list_product_categories.json", data: product_categories)
    end
  end

  defmodule View do
    def render("list_product_categories.json", %{data: categories}) do
      Enum.map(categories, & %{
        id: &1.id,
        name: &1.name,
        description: &1.description,
        products: Enum.map(&1.products, fn product ->
          %{
            id: product.id,
            name: product.name,
            code: product.code,
            removed_datetime: product.removed_datetime,
            latest_price: %{
              id: product.latest_product_price.id,
              price_as_usd: product.latest_product_price.price_as_usd
            }
          }
        end)
      })
    end
  end
end
