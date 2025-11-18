defmodule Mydia.Repo.Migrations.AddCrashReportingToConfigSettingsCategory do
  use Ecto.Migration

  def up do
    # SQLite doesn't support ALTER TABLE to modify CHECK constraints
    # So we need to recreate the table with the updated constraint

    # Step 1: Create a new table with the updated CHECK constraint
    execute """
    CREATE TABLE config_settings_new (
      id TEXT PRIMARY KEY NOT NULL,
      key TEXT NOT NULL UNIQUE,
      value TEXT,
      category TEXT NOT NULL CHECK(category IN ('server', 'auth', 'media', 'downloads', 'notifications', 'crash_reporting', 'general')),
      description TEXT,
      updated_by_id TEXT REFERENCES users(id) ON DELETE SET NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    # Step 2: Copy data from old table to new table
    execute """
    INSERT INTO config_settings_new (id, key, value, category, description, updated_by_id, inserted_at, updated_at)
    SELECT id, key, value, category, description, updated_by_id, inserted_at, updated_at
    FROM config_settings
    """

    # Step 3: Drop the old table
    execute "DROP TABLE config_settings"

    # Step 4: Rename the new table to the original name
    execute "ALTER TABLE config_settings_new RENAME TO config_settings"

    # Step 5: Recreate the indexes
    create index(:config_settings, [:category])
    create index(:config_settings, [:key])
  end

  def down do
    # Revert back to the original CHECK constraint without crash_reporting
    execute """
    CREATE TABLE config_settings_new (
      id TEXT PRIMARY KEY NOT NULL,
      key TEXT NOT NULL UNIQUE,
      value TEXT,
      category TEXT NOT NULL CHECK(category IN ('server', 'auth', 'media', 'downloads', 'notifications', 'general')),
      description TEXT,
      updated_by_id TEXT REFERENCES users(id) ON DELETE SET NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO config_settings_new (id, key, value, category, description, updated_by_id, inserted_at, updated_at)
    SELECT id, key, value, category, description, updated_by_id, inserted_at, updated_at
    FROM config_settings
    WHERE category != 'crash_reporting'
    """

    execute "DROP TABLE config_settings"

    execute "ALTER TABLE config_settings_new RENAME TO config_settings"

    create index(:config_settings, [:category])
    create index(:config_settings, [:key])
  end
end
