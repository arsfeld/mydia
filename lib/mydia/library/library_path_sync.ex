defmodule Mydia.Library.LibraryPathSync do
  @moduledoc """
  Shared module for syncing library paths and populating relative paths in media files.

  Used by both:
  - One-time migration (populate_media_file_relative_paths.exs)
  - Startup task (StartupSync)

  ## Key Responsibilities

  1. **Sync Runtime Library Paths to Database**
     - Reads library paths from runtime config (env vars, YAML)
     - Upserts them to database using path as unique key
     - Ensures database is consistent with current configuration

  2. **Match Files to Library Paths**
     - Uses longest prefix matching to find correct library path for each file
     - Handles edge cases (orphaned files, files outside library paths)

  3. **Calculate Relative Paths**
     - Converts absolute paths to relative paths
     - Stores library_path_id foreign key reference
  """

  require Logger
  import Ecto.Query
  alias Mydia.Repo
  alias Mydia.Settings
  alias Mydia.Settings.LibraryPath
  alias Mydia.Library.MediaFile

  @doc """
  Syncs runtime library paths to the database.

  Reads library paths from `Settings.get_runtime_library_paths/0` and ensures
  they exist in the database. Runtime paths are upserted using the path field
  as the unique key.

  Also disables library paths that were previously created from environment
  variables but are no longer present in the config (sets monitored: false).

  This function is idempotent and safe to call multiple times.

  Returns {:ok, stats} where stats contains:
  - synced: Number of paths synced from env
  - disabled: Number of paths disabled (removed from env)
  """
  def sync_from_runtime_config do
    runtime_paths = Settings.get_runtime_library_paths()

    runtime_path_strings =
      runtime_paths
      |> Enum.filter(&is_runtime_path?/1)
      |> Enum.map(& &1.path)
      |> MapSet.new()

    # Sync runtime paths to database
    synced_count =
      runtime_paths
      |> Enum.filter(&is_runtime_path?/1)
      |> Enum.reduce(0, fn runtime_path, count ->
        case upsert_library_path(runtime_path) do
          {:ok, _} ->
            count + 1

          {:error, changeset} ->
            Logger.warning("Failed to sync runtime library path: #{inspect(changeset.errors)}")
            count
        end
      end)

    # Disable env-sourced paths that are no longer in config
    disabled_count = disable_removed_env_paths(runtime_path_strings)

    {:ok, %{synced: synced_count, disabled: disabled_count}}
  end

  @doc """
  Populates library_path_id and relative_path for all media files.

  Processes all media files in the database:
  1. Finds matching library path (longest prefix)
  2. Calculates relative path
  3. Updates media_files record

  Orphaned files (no matching library path) are logged but not updated.

  Returns {:ok, stats} where stats contains:
  - updated: Number of files successfully updated
  - orphaned: Number of files with no matching library path
  - failed: Number of files that failed to update
  """
  def populate_all_media_files do
    # Get all library paths once (includes both database and runtime)
    all_library_paths = Settings.list_library_paths()

    # Get all media files
    media_files = Repo.all(MediaFile)

    stats = %{updated: 0, orphaned: 0, failed: 0}

    stats =
      Enum.reduce(media_files, stats, fn media_file, acc ->
        case populate_media_file(media_file, all_library_paths) do
          {:ok, :updated} ->
            %{acc | updated: acc.updated + 1}

          {:ok, :orphaned} ->
            Logger.info("Orphaned file (no matching library path): #{media_file.path}")
            %{acc | orphaned: acc.orphaned + 1}

          {:error, reason} ->
            Logger.warning("Failed to update media file #{media_file.path}: #{inspect(reason)}")
            %{acc | failed: acc.failed + 1}
        end
      end)

    {:ok, stats}
  end

  @doc """
  Counts media files that need library_path_id or relative_path populated.

  Used by startup task to determine if any work is needed.
  """
  def count_files_needing_fix do
    MediaFile
    |> where([mf], is_nil(mf.library_path_id) or is_nil(mf.relative_path))
    |> Repo.aggregate(:count)
  end

  ## Private Functions

  # Checks if a library path is from runtime config (not database)
  defp is_runtime_path?(%LibraryPath{id: id}) when is_binary(id) do
    String.starts_with?(id, "runtime::")
  end

  defp is_runtime_path?(_), do: false

  # Upserts a runtime library path to the database
  defp upsert_library_path(%LibraryPath{} = runtime_path) do
    # Check if library path already exists in database
    existing = Repo.get_by(LibraryPath, path: runtime_path.path)

    if existing do
      # Update existing record with runtime config values
      # Mark as from_env and re-enable if previously disabled
      existing
      |> LibraryPath.changeset(%{
        type: runtime_path.type,
        monitored: runtime_path.monitored,
        scan_interval: runtime_path.scan_interval,
        quality_profile_id: runtime_path.quality_profile_id,
        from_env: true,
        disabled: false
      })
      |> Repo.update()
    else
      # Create new record from runtime config
      %LibraryPath{}
      |> LibraryPath.changeset(%{
        path: runtime_path.path,
        type: runtime_path.type,
        monitored: runtime_path.monitored,
        scan_interval: runtime_path.scan_interval,
        quality_profile_id: runtime_path.quality_profile_id,
        from_env: true,
        disabled: false
      })
      |> Repo.insert()
    end
  end

  # Disables library paths that were created from env vars but are no longer in config
  defp disable_removed_env_paths(current_env_paths) do
    # Find all library paths that:
    # 1. Were created from environment variables (from_env: true)
    # 2. Are not already disabled
    # 3. Are NOT in the current env config
    LibraryPath
    |> where([lp], lp.from_env == true and lp.disabled == false)
    |> Repo.all()
    |> Enum.filter(fn lp -> not MapSet.member?(current_env_paths, lp.path) end)
    |> Enum.reduce(0, fn library_path, count ->
      case library_path
           |> LibraryPath.changeset(%{disabled: true})
           |> Repo.update() do
        {:ok, _} ->
          Logger.info("Disabled library path removed from env config: #{library_path.path}")
          count + 1

        {:error, changeset} ->
          Logger.warning(
            "Failed to disable library path #{library_path.path}: #{inspect(changeset.errors)}"
          )

          count
      end
    end)
  end

  # Populates library_path_id and relative_path for a single media file
  defp populate_media_file(media_file, all_library_paths) do
    case find_matching_library_path(media_file.path, all_library_paths) do
      nil ->
        {:ok, :orphaned}

      library_path ->
        relative_path = calculate_relative_path(media_file.path, library_path.path)

        # Get database ID for library path (sync to DB if needed)
        library_path_id = get_or_create_library_path_id(library_path)

        media_file
        |> Ecto.Changeset.change(%{
          library_path_id: library_path_id,
          relative_path: relative_path
        })
        |> Repo.update()
        |> case do
          {:ok, _} -> {:ok, :updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  # Finds the library path that best matches the given file path.
  # Uses longest prefix matching - prefers the most specific path.
  defp find_matching_library_path(file_path, library_paths) do
    library_paths
    |> Enum.filter(fn library_path ->
      String.starts_with?(file_path, library_path.path)
    end)
    |> Enum.max_by(
      fn library_path -> String.length(library_path.path) end,
      fn -> nil end
    )
  end

  # Calculates the relative path by removing the library path prefix
  defp calculate_relative_path(file_path, library_path) do
    # Remove the library path prefix and any leading slash
    file_path
    |> String.replace_prefix(library_path, "")
    |> String.trim_leading("/")
  end

  # Gets the database ID for a library path, creating it if it's a runtime path
  defp get_or_create_library_path_id(%LibraryPath{id: id, path: path}) when is_binary(id) do
    if String.starts_with?(id, "runtime::") do
      # Runtime path - need to get/create database record by path
      case Repo.get_by(LibraryPath, path: path) do
        nil ->
          # This shouldn't happen if sync_from_runtime_config was called first
          # But we'll handle it gracefully
          Logger.warning("Runtime library path not found in database: #{path}")
          nil

        db_path ->
          db_path.id
      end
    else
      # Already a database ID
      id
    end
  end

  defp get_or_create_library_path_id(id) when is_binary(id), do: id
  defp get_or_create_library_path_id(nil), do: nil
end
