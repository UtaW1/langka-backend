defmodule LangkaOrderManagement.Repo.Migrations.AddImageUrlToInventories do
  use Ecto.Migration

  def change do
    alter table(:inventories) do
      add :image_url, :string
    end
  end
end
