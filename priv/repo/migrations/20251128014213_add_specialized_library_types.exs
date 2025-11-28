defmodule Mydia.Repo.Migrations.AddSpecializedLibraryTypes do
  use Ecto.Migration

  @doc """
  Adds music, books, and adult types to the library_paths.type enum.

  SQLite doesn't support ALTER TABLE to modify CHECK constraints, so we need to:
  1. Create a new table with the updated constraint
  2. Copy data from the old table
  3. Drop the old table
  4. Rename the new table
  """
  def change do
    # For SQLite, we need to recreate the table to update the CHECK constraint
    # Create new table with updated type constraint
    execute """
            CREATE TABLE library_paths_new (
              id TEXT PRIMARY KEY NOT NULL,
              path TEXT NOT NULL UNIQUE,
              type TEXT NOT NULL CHECK(type IN ('movies', 'series', 'mixed', 'music', 'books', 'adult')),
              monitored INTEGER DEFAULT 1 CHECK(monitored IN (0, 1)),
              scan_interval INTEGER DEFAULT 3600,
              last_scan_at TEXT,
              last_scan_status TEXT CHECK(last_scan_status IS NULL OR last_scan_status IN ('success', 'failed', 'in_progress')),
              last_scan_error TEXT,
              quality_profile_id TEXT REFERENCES quality_profiles(id) ON DELETE SET NULL,
              updated_by_id TEXT REFERENCES users(id) ON DELETE SET NULL,
              inserted_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE library_paths_new (
              id TEXT PRIMARY KEY NOT NULL,
              path TEXT NOT NULL UNIQUE,
              type TEXT NOT NULL CHECK(type IN ('movies', 'series', 'mixed')),
              monitored INTEGER DEFAULT 1 CHECK(monitored IN (0, 1)),
              scan_interval INTEGER DEFAULT 3600,
              last_scan_at TEXT,
              last_scan_status TEXT CHECK(last_scan_status IS NULL OR last_scan_status IN ('success', 'failed', 'in_progress')),
              last_scan_error TEXT,
              quality_profile_id TEXT REFERENCES quality_profiles(id) ON DELETE SET NULL,
              updated_by_id TEXT REFERENCES users(id) ON DELETE SET NULL,
              inserted_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
            """

    # Copy existing data
    execute """
            INSERT INTO library_paths_new
            SELECT id, path, type, monitored, scan_interval, last_scan_at, last_scan_status,
                   last_scan_error, quality_profile_id, updated_by_id, inserted_at, updated_at
            FROM library_paths
            """,
            """
            INSERT INTO library_paths_new
            SELECT id, path, type, monitored, scan_interval, last_scan_at, last_scan_status,
                   last_scan_error, quality_profile_id, updated_by_id, inserted_at, updated_at
            FROM library_paths
            """

    # Drop old table
    execute "DROP TABLE library_paths", "DROP TABLE library_paths"

    # Rename new table to library_paths
    execute "ALTER TABLE library_paths_new RENAME TO library_paths",
            "ALTER TABLE library_paths_new RENAME TO library_paths"

    # Recreate indexes
    execute "CREATE INDEX library_paths_monitored_index ON library_paths (monitored)",
            "CREATE INDEX library_paths_monitored_index ON library_paths (monitored)"

    execute "CREATE INDEX library_paths_type_index ON library_paths (type)",
            "CREATE INDEX library_paths_type_index ON library_paths (type)"

    execute "CREATE INDEX library_paths_quality_profile_id_index ON library_paths (quality_profile_id)",
            "CREATE INDEX library_paths_quality_profile_id_index ON library_paths (quality_profile_id)"
  end
end
