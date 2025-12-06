defmodule Mydia.Repo.Migrations.AddGeneratedMediaFieldsToMediaFiles do
  use Ecto.Migration

  def change do
    alter table(:media_files) do
      # MD5 checksums for generated content (used as storage keys)
      add :cover_blob, :string
      add :sprite_blob, :string
      add :vtt_blob, :string
      add :preview_blob, :string

      # Perceptual hash for duplicate detection
      add :phash, :string

      # Timestamp when generated content was last created
      add :generated_at, :utc_datetime
    end

    # Index for duplicate detection queries
    create index(:media_files, [:phash])
  end
end
