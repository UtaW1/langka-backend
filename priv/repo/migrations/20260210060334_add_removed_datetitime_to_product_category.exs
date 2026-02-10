defmodule LangkaOrderManagement.Repo.Migrations.AddRemovedDatetitimeToProductCategory do
  use Ecto.Migration

  def change do
    alter table(:product_categories) do
      add :removed_datetime, :utc_datetime
      add :removed_reason, :string
    end
  end
end
