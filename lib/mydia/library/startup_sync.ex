defmodule Mydia.Library.StartupSync do
  @moduledoc """
  Startup task that syncs library paths and ensures media files have relative paths populated.

  Runs on every application boot to:
  1. Sync runtime library paths to database (env vars may change between boots)
  2. Fix any media files missing library_path_id or relative_path (safety net)

  After the initial migration completes and Phase 3 code changes are deployed,
  this task will find 0 files needing fixes and complete instantly.

  ## Performance

  - First boot after migration: Syncs library paths (fast upsert) + fixes any edge cases
  - Subsequent boots: Syncs library paths + quick count query (should be 0 files)
  - Optimized for the common case: instant return when no work needed
  """

  require Logger
  alias Mydia.Library.LibraryPathSync

  @doc """
  Syncs all library paths and fixes media files missing relative paths.

  This is called during application startup to ensure:
  1. Runtime library paths are always synced to database
  2. Any files missing relative_path are fixed (safety net)

  Returns :ok on success.
  """
  def sync_all do
    start_time = System.monotonic_time(:millisecond)

    try do
      # 1. Always sync library paths (env vars may change between boots)
      {:ok, %{synced: synced_count, disabled: disabled_count}} =
        LibraryPathSync.sync_from_runtime_config()

      if synced_count > 0 do
        Logger.info("[StartupSync] Synced #{synced_count} runtime library paths to database")
      end

      if disabled_count > 0 do
        Logger.info(
          "[StartupSync] Disabled #{disabled_count} library paths removed from env config"
        )
      end

      # 2. Quick check for files needing fix (should be 0 after initial migration)
      files_needing_fix = LibraryPathSync.count_files_needing_fix()

      if files_needing_fix > 0 do
        Logger.info(
          "[StartupSync] Found #{files_needing_fix} media files needing relative path population"
        )

        # Fix the files
        {:ok, stats} = LibraryPathSync.populate_all_media_files()

        Logger.info("""
        [StartupSync] Populated relative paths:
          - Updated: #{stats.updated}
          - Orphaned: #{stats.orphaned}
          - Failed: #{stats.failed}
        """)

        if stats.orphaned > 0 do
          Logger.warning(
            "[StartupSync] Found #{stats.orphaned} orphaned files (outside configured library paths)"
          )
        end

        if stats.failed > 0 do
          Logger.error("[StartupSync] Failed to update #{stats.failed} files")
        end
      end

      elapsed = System.monotonic_time(:millisecond) - start_time
      Logger.debug("[StartupSync] Completed in #{elapsed}ms")

      :ok
    rescue
      error ->
        Logger.error("[StartupSync] Failed: #{inspect(error)}")
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        :ok
    end
  end
end
