defmodule Mydia.Repo.Migrations.AddFlaresolverrFieldsToCardigannDefinitions do
  use Ecto.Migration

  def change do
    alter table(:cardigann_definitions) do
      # Whether this indexer requires FlareSolverr (auto-detected or manually set)
      add :flaresolverr_required, :boolean, default: false

      # User preference to enable/disable FlareSolverr for this indexer
      add :flaresolverr_enabled, :boolean, default: false
    end

    # Index for filtering indexers that need FlareSolverr
    create index(:cardigann_definitions, [:flaresolverr_required])
    create index(:cardigann_definitions, [:flaresolverr_enabled])
  end
end
