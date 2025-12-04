defmodule Mydia.Repo.Migrations.MakeDownloadClientHostPortNullable do
  @moduledoc """
  Make host and port nullable for download client configs.

  Blackhole clients use folder paths from connection_settings instead of
  host/port, so these fields should be optional.

  SQLite: Recreates the table (doesn't support ALTER COLUMN).
  PostgreSQL: Uses ALTER COLUMN DROP NOT NULL.
  """
  use Ecto.Migration
  import Mydia.Repo.Migrations.Helpers

  def up do
    for_database(
      sqlite: fn -> sqlite_recreate_table_nullable() end,
      postgres: fn ->
        execute "ALTER TABLE download_client_configs ALTER COLUMN host DROP NOT NULL"
        execute "ALTER TABLE download_client_configs ALTER COLUMN port DROP NOT NULL"
      end
    )
  end

  def down do
    for_database(
      sqlite: fn -> sqlite_recreate_table_not_null() end,
      postgres: fn ->
        # May fail if null values exist
        execute "ALTER TABLE download_client_configs ALTER COLUMN host SET NOT NULL"
        execute "ALTER TABLE download_client_configs ALTER COLUMN port SET NOT NULL"
      end
    )
  end

  # SQLite: Recreate table with nullable host and port
  defp sqlite_recreate_table_nullable do
    execute """
    CREATE TABLE download_client_configs_new (
      id BLOB PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      enabled INTEGER DEFAULT 1,
      priority INTEGER DEFAULT 1,
      host TEXT,
      port INTEGER,
      use_ssl INTEGER DEFAULT 0,
      url_base TEXT,
      username TEXT,
      password TEXT,
      api_key TEXT,
      category TEXT,
      download_directory TEXT,
      connection_settings TEXT,
      updated_by_id BLOB REFERENCES users(id) ON DELETE SET NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute "INSERT INTO download_client_configs_new SELECT * FROM download_client_configs"
    execute "DROP TABLE download_client_configs"
    execute "ALTER TABLE download_client_configs_new RENAME TO download_client_configs"

    create unique_index(:download_client_configs, [:name])
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])
  end

  # SQLite: Recreate table with NOT NULL host and port
  defp sqlite_recreate_table_not_null do
    execute """
    CREATE TABLE download_client_configs_new (
      id BLOB PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      enabled INTEGER DEFAULT 1,
      priority INTEGER DEFAULT 1,
      host TEXT NOT NULL,
      port INTEGER NOT NULL,
      use_ssl INTEGER DEFAULT 0,
      url_base TEXT,
      username TEXT,
      password TEXT,
      api_key TEXT,
      category TEXT,
      download_directory TEXT,
      connection_settings TEXT,
      updated_by_id BLOB REFERENCES users(id) ON DELETE SET NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute "INSERT INTO download_client_configs_new SELECT * FROM download_client_configs"
    execute "DROP TABLE download_client_configs"
    execute "ALTER TABLE download_client_configs_new RENAME TO download_client_configs"

    create unique_index(:download_client_configs, [:name])
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])
  end
end
