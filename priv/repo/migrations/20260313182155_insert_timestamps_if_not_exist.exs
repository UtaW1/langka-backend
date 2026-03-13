defmodule LangkaOrderManagement.Repo.Migrations.InsertTimestampsIfNotExist do
  use Ecto.Migration

  def change do
    alter table(:seating_tables) do
      add_if_not_exists :inserted_at, :utc_datetime_usec
      add_if_not_exists :updated_at, :utc_datetime_usec
    end
  end
end
