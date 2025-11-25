defmodule Mydia.Repo.Migrations.CreateSubtitleTables do
  use Ecto.Migration

  def change do
    # Subtitles table: stores downloaded subtitle metadata and file paths
    create table(:subtitles, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :media_file_id, references(:media_files, type: :binary_id, on_delete: :delete_all),
        null: false

      add :language, :string, null: false
      add :provider, :string, null: false
      add :subtitle_hash, :string, null: false
      add :file_path, :string, null: false
      add :sync_offset, :integer, default: 0
      add :format, :string, null: false
      add :rating, :float
      add :download_count, :integer
      add :hearing_impaired, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:subtitles, [:subtitle_hash])
    create index(:subtitles, [:media_file_id])
    create index(:subtitles, [:language])

    # Media hashes table: stores OpenSubtitles moviehash for each media file
    # Enables fast hash-based subtitle matching
    create table(:media_hashes, primary_key: false) do
      add :media_file_id, references(:media_files, type: :binary_id, on_delete: :delete_all),
        primary_key: true

      add :opensubtitles_hash, :string, null: false
      add :file_size, :bigint, null: false
      add :calculated_at, :utc_datetime, null: false
    end

    create index(:media_hashes, [:opensubtitles_hash])
  end
end
