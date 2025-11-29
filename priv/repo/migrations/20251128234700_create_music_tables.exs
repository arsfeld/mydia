defmodule Mydia.Repo.Migrations.CreateMusicTables do
  use Ecto.Migration

  def change do
    # Artists table
    create table(:artists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :sort_name, :string
      add :musicbrainz_id, :string
      add :biography, :text
      add :image_url, :string
      add :genres, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:artists, [:musicbrainz_id], where: "musicbrainz_id IS NOT NULL")
    create index(:artists, [:name])
    create index(:artists, [:sort_name])

    # Albums table
    create table(:albums, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :artist_id, references(:artists, type: :binary_id, on_delete: :delete_all), null: false
      add :release_date, :date
      add :album_type, :string, default: "album"
      add :musicbrainz_id, :string
      add :cover_url, :string
      add :genres, {:array, :string}, default: []
      add :total_tracks, :integer
      add :total_duration, :integer
      add :monitored, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:albums, [:musicbrainz_id], where: "musicbrainz_id IS NOT NULL")
    create index(:albums, [:artist_id])
    create index(:albums, [:title])
    create index(:albums, [:release_date])

    # Tracks table
    create table(:tracks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :album_id, references(:albums, type: :binary_id, on_delete: :delete_all), null: false
      add :artist_id, references(:artists, type: :binary_id, on_delete: :nilify_all)
      add :track_number, :integer
      add :disc_number, :integer, default: 1
      add :duration, :integer
      add :musicbrainz_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tracks, [:musicbrainz_id], where: "musicbrainz_id IS NOT NULL")
    create index(:tracks, [:album_id])
    create index(:tracks, [:artist_id])
    create unique_index(:tracks, [:album_id, :disc_number, :track_number])

    # Music files table
    create table(:music_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :track_id, references(:tracks, type: :binary_id, on_delete: :delete_all)
      add :library_path_id, references(:library_paths, type: :binary_id, on_delete: :nilify_all)
      add :path, :string, null: false
      add :relative_path, :string
      add :size, :bigint
      add :bitrate, :integer
      add :sample_rate, :integer
      add :codec, :string
      add :channels, :integer
      add :duration, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:music_files, [:path])
    create index(:music_files, [:track_id])
    create index(:music_files, [:library_path_id])
  end
end
