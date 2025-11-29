defmodule Mydia.Music.Album do
  @moduledoc """
  Schema for music albums.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @album_types ~w(album single ep compilation)

  schema "albums" do
    field :title, :string
    field :release_date, :date
    field :album_type, :string, default: "album"
    field :musicbrainz_id, :string
    field :cover_url, :string
    field :genres, {:array, :string}, default: []
    field :total_tracks, :integer
    field :total_duration, :integer
    field :monitored, :boolean, default: true

    belongs_to :artist, Mydia.Music.Artist
    has_many :tracks, Mydia.Music.Track

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating an album.
  """
  def changeset(album, attrs) do
    album
    |> cast(attrs, [
      :title,
      :artist_id,
      :release_date,
      :album_type,
      :musicbrainz_id,
      :cover_url,
      :genres,
      :total_tracks,
      :total_duration,
      :monitored
    ])
    |> validate_required([:title, :artist_id])
    |> validate_inclusion(:album_type, @album_types)
    |> unique_constraint(:musicbrainz_id)
    |> foreign_key_constraint(:artist_id)
  end

  @doc """
  Returns the list of valid album types.
  """
  def valid_album_types, do: @album_types
end
