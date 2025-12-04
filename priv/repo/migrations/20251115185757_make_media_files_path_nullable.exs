defmodule Mydia.Repo.Migrations.MakeMediaFilesPathNullable do
  @moduledoc """
  Make the `path` column nullable in `media_files` table.

  The `path` field is deprecated in favor of `relative_path` + `library_path_id`.
  This migration allows new media files to be created without an absolute path.

  Note: SQLite doesn't support ALTER COLUMN, so we recreate the table.
  PostgreSQL supports ALTER COLUMN directly.
  """

  use Ecto.Migration
  import Mydia.Repo.Migrations.Helpers

  def up do
    # Drop the unique index on path first
    drop_if_exists unique_index(:media_files, [:path])

    # Use database-specific approach
    if postgres?() do
      # PostgreSQL: simply alter the column
      execute "ALTER TABLE media_files ALTER COLUMN path DROP NOT NULL"
    else
      # SQLite: recreate the table with nullable path
      # First, rename the existing table
      rename table(:media_files), to: table(:media_files_old)

      # Create new table with nullable path
      create table(:media_files, primary_key: false) do
        add :id, :binary_id, primary_key: true
        add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all)
        add :episode_id, references(:episodes, type: :binary_id, on_delete: :delete_all)
        # Now nullable
        add :path, :string
        add :size, :bigint
        add :quality_profile_id, references(:quality_profiles, type: :binary_id)
        add :resolution, :string
        add :codec, :string
        add :hdr_format, :string
        add :audio_codec, :string
        add :bitrate, :integer
        add :verified_at, :utc_datetime
        add :metadata, :text
        add :relative_path, :string
        add :library_path_id, references(:library_paths, type: :binary_id, on_delete: :delete_all)

        timestamps(type: :utc_datetime)
      end

      # Copy data from old table
      execute """
      INSERT INTO media_files (id, media_item_id, episode_id, path, size, quality_profile_id,
                               resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
                               metadata, relative_path, library_path_id, inserted_at, updated_at)
      SELECT id, media_item_id, episode_id, path, size, quality_profile_id,
             resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
             metadata, relative_path, library_path_id, inserted_at, updated_at
      FROM media_files_old
      """

      # Drop old table
      drop table(:media_files_old)

      # Recreate indexes
      create index(:media_files, [:media_item_id])
      create index(:media_files, [:episode_id])
      create index(:media_files, [:library_path_id])
    end
  end

  def down do
    if postgres?() do
      # PostgreSQL: add NOT NULL back (will fail if there are NULL values)
      execute "ALTER TABLE media_files ALTER COLUMN path SET NOT NULL"
      create unique_index(:media_files, [:path])
    else
      # SQLite: recreate with NOT NULL constraint
      rename table(:media_files), to: table(:media_files_old)

      create table(:media_files, primary_key: false) do
        add :id, :binary_id, primary_key: true
        add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all)
        add :episode_id, references(:episodes, type: :binary_id, on_delete: :delete_all)
        add :path, :string, null: false
        add :size, :bigint
        add :quality_profile_id, references(:quality_profiles, type: :binary_id)
        add :resolution, :string
        add :codec, :string
        add :hdr_format, :string
        add :audio_codec, :string
        add :bitrate, :integer
        add :verified_at, :utc_datetime
        add :metadata, :text
        add :relative_path, :string
        add :library_path_id, references(:library_paths, type: :binary_id, on_delete: :delete_all)

        timestamps(type: :utc_datetime)
      end

      execute """
      INSERT INTO media_files (id, media_item_id, episode_id, path, size, quality_profile_id,
                               resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
                               metadata, relative_path, library_path_id, inserted_at, updated_at)
      SELECT id, media_item_id, episode_id, path, size, quality_profile_id,
             resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
             metadata, relative_path, library_path_id, inserted_at, updated_at
      FROM media_files_old
      """

      drop table(:media_files_old)

      create unique_index(:media_files, [:path])
      create index(:media_files, [:media_item_id])
      create index(:media_files, [:episode_id])
      create index(:media_files, [:library_path_id])
    end
  end
end
