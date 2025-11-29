defmodule Mydia.Music.Track do
  @moduledoc """
  Schema for music tracks.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tracks" do
    field :title, :string
    field :track_number, :integer
    field :disc_number, :integer, default: 1
    field :duration, :integer
    field :musicbrainz_id, :string

    belongs_to :album, Mydia.Music.Album
    belongs_to :artist, Mydia.Music.Artist
    has_many :music_files, Mydia.Music.MusicFile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a track.
  """
  def changeset(track, attrs) do
    track
    |> cast(attrs, [
      :title,
      :album_id,
      :artist_id,
      :track_number,
      :disc_number,
      :duration,
      :musicbrainz_id
    ])
    |> validate_required([:title, :album_id])
    |> validate_number(:track_number, greater_than: 0)
    |> validate_number(:disc_number, greater_than: 0)
    |> validate_number(:duration, greater_than_or_equal_to: 0)
    |> unique_constraint(:musicbrainz_id)
    |> unique_constraint([:album_id, :disc_number, :track_number])
    |> foreign_key_constraint(:album_id)
    |> foreign_key_constraint(:artist_id)
  end
end
