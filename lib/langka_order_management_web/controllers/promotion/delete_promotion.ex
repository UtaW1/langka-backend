defmodule LangkaOrderManagementWeb.DeletePromotion do
  alias LangkaOrderManagement.Promotion

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with promotion when not is_nil(promotion) <- Promotion.get_promotion(id),
         {:ok, _} <- Promotion.retire_promotion(promotion)
      do
        Plug.Conn.send_resp(conn, 204, "")
      else
        nil ->
          ControllerUtils.render_error(conn, 404, "404.json", "promotion not found", "no exist")

        {:error, :promotion_in_unactive_state} ->
          Plug.Conn.send_resp(conn, 204, "")
    end
  end
end
