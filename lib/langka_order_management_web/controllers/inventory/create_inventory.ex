defmodule LangkaOrderManagementWeb.CreateInventory do
  alias LangkaOrderManagement.Inventory
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "name" => [required: true, nullable: false, type: :string],
      "note" => [required: false, nullable: true, type: :string],
      "inventory_image" => [required: false, custom: &ControllerUtils.validate_images/1]
    }
  end

  def perform(conn, args) do
    with {:ok, created_inventory} <- Inventory.create_inventory(args),
         {:ok, _uploaded_inventory} <- Inventory.upload_inventory_image(args["inventory_image"], created_inventory),
         %{inventory: inventory, actual_quantity: actual_quantity} <-
           Inventory.get_inventory_with_actual_quantity(created_inventory.id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_inventory.json", data: {inventory, actual_quantity})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("400.json", %{error: :changeset_error, message: "changeset error #{inspect(changeset)}"})

      {:error, %{upload_error: _} = upload_error} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("400.json", %{error: :upload_error, message: "upload failed #{inspect(upload_error)}"})

      err ->
        conn
        |> Plug.Conn.put_status(:internal_server_error)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("500.json", %{error: {:unexpected_error, inspect(err)}})
    end
  end

  defmodule View do
    def render("create_inventory.json", %{data: {inventory, actual_quantity}}) do
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
    end
  end
end
