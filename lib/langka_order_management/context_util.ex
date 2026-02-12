defmodule LangkaOrderManagement.ContextUtil do
  @moduledoc false

  import Ecto.Query, warn: false

  def construct_csv_content_for_export(%{columns: columns, rows: rows}, header, params) do
    start_date =
      if params["start_date"] do
        Map.get(params, "start_date", "none")
      else
        Map.get(params, "start_datetime", "none")
      end

    end_date =
      if params["end_date"] do
        Map.get(params, "end_date", "none")
      else
        Map.get(params, "end_datetime", "none")
      end

    dir = Map.get(params, "dir", "#{String.replace(header, " ", "-")}.xlsx")

        string_columns = Enum.map(columns, fn col ->
      case col do
        col when is_atom(col) -> Atom.to_string(col)
        col -> col
      end
    end)

    metadata_rows = [
      [header] ++ List.duplicate("", length(columns) - 1),
      ["Generated on: #{Date.utc_today()}"] ++ List.duplicate("", length(columns) - 1),
      ["From #{start_date} To #{end_date}"] ++ List.duplicate("", length(columns) - 1),
      List.duplicate("", length(columns))
    ]

    data_rows = Enum.map(rows, fn row ->
      Enum.map(columns, fn col ->
        "#{Map.get(row, col, "")}"
      end)
    end)

    all_rows = metadata_rows ++ [string_columns] ++ data_rows

    sheet = %Elixlsx.Sheet{
      name: "Exported Data",
      rows: all_rows
    }

    workbook = %Elixlsx.Workbook{sheets: [sheet]}

    {:ok, {_file_path, binary}} = Elixlsx.write_to_memory(workbook, dir)

    binary
  end

  def list(query, filters) do
    limit = get_record_listing_limit(filters)

    sorting =
      if filters["sort"] == "asc" do
        [asc: :id]
      else
        [desc: :id]
      end

    cursor_paging =
      case {filters["sort"], filters["cursor_id"]} do
        {_, cursor_id} when cursor_id in [0, nil] ->
          dynamic(true)

        {"asc", cursor_id} ->
          dynamic([x], x.id > ^cursor_id)

        {_, cursor_id} ->
          dynamic([x], x.id < ^cursor_id)
      end

    filters
    |> Enum.reduce(query, fn
      {"label", name}, query ->
        where(query, [x], ilike(x.name, ^"%#{name}%"))

      {"ids.not_in", ids}, query ->
        where(query, [x], x.id not in ^ids)

      {ids_query, ids}, query when ids_query in ["ids", "ids.in"] ->
        where(query, [x], x.id in ^ids)

      {"page_number", page_number}, query ->
        offset(query, ^(page_number * limit))

      {"is_removed", is_removed}, query ->
        where(query, [x], not is_nil(x.removed_datetime) == ^(is_removed == "yes"))

      _, query -> query
    end)
    |> where(^cursor_paging)
    |> order_by(^sorting)
    |> limit(^limit)
  end

  defp get_record_listing_limit(%{"limit" => lim}), do: lim

  defp get_record_listing_limit(%{"page_size" => lim}), do: lim

  defp get_record_listing_limit(_), do: 16
end
