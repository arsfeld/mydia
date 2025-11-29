defmodule Mydia.Repo.Migrations.PopulateMediaFileRelativePaths do
  @moduledoc """
  One-time migration to populate library_path_id and relative_path for existing media files.

  This migration:
  1. Syncs runtime library paths to database
  2. Populates relative_path and library_path_id for all existing media files
  3. Logs orphaned files (files outside configured library paths)

  Note: A startup task (Mydia.Library.StartupSync) will handle ongoing synchronization
  and act as a safety net for edge cases.
  """

  use Ecto.Migration

  def up do
    # Use the shared LibraryPathSync module to populate paths
    alias Mydia.Library.LibraryPathSync

    # 1. Sync runtime library paths to database
    # This ensures all library paths from env vars/YAML are in the database
    {:ok, %{synced: synced_count}} = LibraryPathSync.sync_from_runtime_config()

    IO.puts("""

    [Migration] Synced #{synced_count} runtime library paths to database
    """)

    # 2. Populate relative_path and library_path_id for all media files
    {:ok, stats} = LibraryPathSync.populate_all_media_files()

    IO.puts("""
    [Migration] Populated relative paths for media files:
      - Updated: #{stats.updated}
      - Orphaned: #{stats.orphaned}
      - Failed: #{stats.failed}
    """)

    if stats.orphaned > 0 do
      IO.puts("""

      [Warning] Found #{stats.orphaned} orphaned files (no matching library path).
      These files are outside your configured library paths and will not be updated.
      Check the logs for details.
      """)
    end

    if stats.failed > 0 do
      IO.puts("""

      [Error] Failed to update #{stats.failed} files.
      Check the logs for details and consider running the migration again.
      """)
    end
  end

  def down do
    # Rollback: Clear library_path_id and relative_path for all media files
    import Ecto.Query

    from("media_files")
    |> repo().update_all(set: [library_path_id: nil, relative_path: nil])

    IO.puts("""

    [Rollback] Cleared library_path_id and relative_path for all media files
    """)
  end
end
