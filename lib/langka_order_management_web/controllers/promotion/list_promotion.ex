defmodule LangkaOrderManagementWeb.ListPromotion do
  alias LangkaOrderManagement.Promotion
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 32}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
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
    with {promotions, total_count} <- Promotion.list_promotions_with_paging(filters) do
      conn
      |> Plug.Conn.put_resp_header("x-paging-total-count", "#{total_count}")
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("list_promotion.json", data: promotions)
    end
  end

  defmodule View do
    def render("list_promotion.json", %{data: promotions}) do
      Enum.map(promotions, & %{
        id: &1.id,
        transaction_count_to_get_discount: &1.transaction_count_to_get_discount,
        discount_as_percent: &1.discount_as_percent,
        status: &1.status,
        inserted_at: &1.inserted_at
      })
    end
  end
end
