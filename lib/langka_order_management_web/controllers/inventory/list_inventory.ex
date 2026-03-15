defmodule LangkaOrderManagementWeb.ListInventory do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "label" => [required: false, nullable: true, type: :string],
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 32}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "is_removed" => [required: false, nullable: true, custom: &ControllerUtils.validate_boolean/1]
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
    {inventories, count} = Inventory.list_inventories_with_paging(filters)

    conn
    |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_inventory.json", data: inventories)
  end

  defmodule View do
    def render("list_inventory.json", %{data: inventories}) do
      Enum.map(inventories, fn %{inventory: inventory, actual_quantity: actual_quantity} ->
        %{
          id: inventory.id,
          name: inventory.name,
          note: inventory.note,
          image_url: inventory.image_url,
          removed_datetime: inventory.removed_datetime,
          actual_quantity: actual_quantity,
          inserted_at: inventory.inserted_at,
          updated_at: inventory.updated_at
        }
      end)
    end
  end
end
