defmodule LangkaOrderManagement.Release do
  def migrate do
    Application.load(:langka_order_management)

    for repo <- Application.fetch_env!(:langka_order_management, :ecto_repos) do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
