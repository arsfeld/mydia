defmodule Mydia.Repo.Migrations.CreateCardigannDefinitions do
  use Ecto.Migration

  def change do
    # Cardigann definitions table: stores indexer definitions from Prowlarr/Cardigann
    create table(:cardigann_definitions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :indexer_id, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :language, :string
      add :type, :string, null: false
      add :encoding, :string
      add :links, :text, null: false
      add :capabilities, :text, null: false
      add :definition, :text, null: false
      add :schema_version, :string, null: false
      add :enabled, :boolean, null: false, default: false
      add :config, :text
      add :last_synced_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cardigann_definitions, [:indexer_id])
    create index(:cardigann_definitions, [:enabled])
    create index(:cardigann_definitions, [:type])

    # Cardigann search sessions table: manages login sessions for private indexers
    create table(:cardigann_search_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :cardigann_definition_id,
          references(:cardigann_definitions, type: :binary_id, on_delete: :delete_all),
          null: false

      add :cookies, :text, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:cardigann_search_sessions, [:cardigann_definition_id])
    create index(:cardigann_search_sessions, [:expires_at])
  end
end
