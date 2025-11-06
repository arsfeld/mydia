defmodule Mydia.Repo.Migrations.RelaxMediaFilesParentConstraint do
  use Ecto.Migration

  def up do
    # SQLite doesn't support modifying constraints directly, so we need to recreate the table
    execute """
    CREATE TABLE media_files_new (
      id TEXT PRIMARY KEY NOT NULL,
      media_item_id TEXT REFERENCES media_items(id) ON DELETE CASCADE,
      episode_id TEXT REFERENCES episodes(id) ON DELETE CASCADE,
      path TEXT NOT NULL UNIQUE,
      size INTEGER,
      quality_profile_id TEXT REFERENCES quality_profiles(id),
      resolution TEXT,
      codec TEXT,
      hdr_format TEXT,
      audio_codec TEXT,
      bitrate INTEGER,
      verified_at TEXT,
      metadata TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK(
        NOT (media_item_id IS NOT NULL AND episode_id IS NOT NULL)
      )
    )
    """

    # Copy existing data
    execute """
    INSERT INTO media_files_new
    SELECT * FROM media_files
    """

    # Drop old table
    execute "DROP TABLE media_files"

    # Rename new table
    execute "ALTER TABLE media_files_new RENAME TO media_files"

    # Recreate indexes
    create index(:media_files, [:media_item_id])
    create index(:media_files, [:episode_id])
  end

  def down do
    # Restore the original constraint
    execute """
    CREATE TABLE media_files_new (
      id TEXT PRIMARY KEY NOT NULL,
      media_item_id TEXT REFERENCES media_items(id) ON DELETE CASCADE,
      episode_id TEXT REFERENCES episodes(id) ON DELETE CASCADE,
      path TEXT NOT NULL UNIQUE,
      size INTEGER,
      quality_profile_id TEXT REFERENCES quality_profiles(id),
      resolution TEXT,
      codec TEXT,
      hdr_format TEXT,
      audio_codec TEXT,
      bitrate INTEGER,
      verified_at TEXT,
      metadata TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK(
        (media_item_id IS NOT NULL AND episode_id IS NULL) OR
        (media_item_id IS NULL AND episode_id IS NOT NULL)
      )
    )
    """

    execute """
    INSERT INTO media_files_new
    SELECT * FROM media_files
    WHERE (media_item_id IS NOT NULL AND episode_id IS NULL) OR
          (media_item_id IS NULL AND episode_id IS NOT NULL)
    """

    execute "DROP TABLE media_files"

    execute "ALTER TABLE media_files_new RENAME TO media_files"

    create index(:media_files, [:media_item_id])
    create index(:media_files, [:episode_id])
  end
end
