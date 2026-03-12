defmodule LangkaOrderManagement.Repo.Migrations.AddImageUrlToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :image_url, :string
    end
  end
end
