defmodule LangkaOrderManagementWeb.ExportUser do
  alias LangkaOrderManagement.{Supabase, Report}
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "start_datetime" => [required: true, nullable: false, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: true, nullable: false, custom: &ControllerUtils.validate_iso8601_datetime/1]
    }
  end

  def perform(conn, args) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.slice(0..18)
      |> String.replace(~r/[^0-9]/, "")

    directory = "/user/user-report-#{timestamp}.xlsx"
    bucket_name = "xlsx-files"

    args = Map.put(args, "dir", directory)

    case Supabase.get_download_url(%{file_path: directory, bucket_name: bucket_name}) do
      {:ok, url} ->
        upload_resp({:ok, url}, conn)

      {:error, "404"} ->
        Report.list_users_for_export(args)
        |> Report.construct_xlsx_for_export("User Report", args)
        |> ControllerUtils.upload_to_storage_and_get_url(bucket_name, directory)
        |> upload_resp(conn)

      {:error, reason} ->
        ControllerUtils.render_error(conn, 500, "500.json", "Unexpected error occured", "#{Kernel.inspect(reason)}")
    end
  end

  defp upload_resp({:ok, url}, conn) do
    conn
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("buh.json", data: url)
  end

  defmodule View do
    def render("buh.json", %{data: url}) do
      %{
        download_url: url
      }
    end
  end
end
