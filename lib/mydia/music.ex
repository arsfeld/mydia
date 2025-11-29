defmodule Mydia.Music do
  @moduledoc """
  The Music context handles music library functionality including artists, albums, and tracks.
  """

  import Ecto.Query, warn: false
  alias Mydia.Repo
  alias Mydia.Music.{Artist, Album, Track, MusicFile}

  ## Artists

  @doc """
  Returns the list of artists.

  ## Options
    - `:preload` - List of associations to preload
    - `:search` - Search term for filtering by name
  """
  def list_artists(opts \\ []) do
    Artist
    |> apply_artist_filters(opts)
    |> order_by([a], asc: fragment("COALESCE(?, ?)", a.sort_name, a.name))
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Gets a single artist.

  Raises `Ecto.NoResultsError` if the Artist does not exist.
  """
  def get_artist!(id, opts \\ []) do
    Artist
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets an artist by MusicBrainz ID.
  """
  def get_artist_by_musicbrainz(musicbrainz_id) do
    Repo.get_by(Artist, musicbrainz_id: musicbrainz_id)
  end

  @doc """
  Creates an artist.
  """
  def create_artist(attrs \\ %{}) do
    %Artist{}
    |> Artist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an artist.
  """
  def update_artist(%Artist{} = artist, attrs) do
    artist
    |> Artist.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an artist.
  """
  def delete_artist(%Artist{} = artist) do
    Repo.delete(artist)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking artist changes.
  """
  def change_artist(%Artist{} = artist, attrs \\ %{}) do
    Artist.changeset(artist, attrs)
  end

  ## Albums

  @doc """
  Returns the list of albums.

  ## Options
    - `:preload` - List of associations to preload
    - `:artist_id` - Filter by artist ID
    - `:search` - Search term for filtering by title
    - `:monitored` - Filter by monitored status
    - `:album_type` - Filter by album type
  """
  def list_albums(opts \\ []) do
    Album
    |> apply_album_filters(opts)
    |> order_by([a], desc: a.release_date, asc: a.title)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Returns the count of albums.
  """
  def count_albums(opts \\ []) do
    Album
    |> apply_album_filters(opts)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single album.

  Raises `Ecto.NoResultsError` if the Album does not exist.
  """
  def get_album!(id, opts \\ []) do
    Album
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets an album by MusicBrainz ID.
  """
  def get_album_by_musicbrainz(musicbrainz_id) do
    Repo.get_by(Album, musicbrainz_id: musicbrainz_id)
  end

  @doc """
  Creates an album.
  """
  def create_album(attrs \\ %{}) do
    %Album{}
    |> Album.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an album.
  """
  def update_album(%Album{} = album, attrs) do
    album
    |> Album.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an album.
  """
  def delete_album(%Album{} = album) do
    Repo.delete(album)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking album changes.
  """
  def change_album(%Album{} = album, attrs \\ %{}) do
    Album.changeset(album, attrs)
  end

  ## Tracks

  @doc """
  Returns the list of tracks.

  ## Options
    - `:preload` - List of associations to preload
    - `:album_id` - Filter by album ID
    - `:artist_id` - Filter by artist ID
  """
  def list_tracks(opts \\ []) do
    Track
    |> apply_track_filters(opts)
    |> order_by([t], asc: t.disc_number, asc: t.track_number)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Gets a single track.

  Raises `Ecto.NoResultsError` if the Track does not exist.
  """
  def get_track!(id, opts \\ []) do
    Track
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Creates a track.
  """
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a track.
  """
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a track.
  """
  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  ## Music Files

  @doc """
  Returns the list of music files.

  ## Options
    - `:preload` - List of associations to preload
    - `:track_id` - Filter by track ID
    - `:library_path_id` - Filter by library path ID
  """
  def list_music_files(opts \\ []) do
    MusicFile
    |> apply_music_file_filters(opts)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Gets a single music file.

  Raises `Ecto.NoResultsError` if the MusicFile does not exist.
  """
  def get_music_file!(id, opts \\ []) do
    MusicFile
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets a music file by path.
  """
  def get_music_file_by_path(path) do
    Repo.get_by(MusicFile, path: path)
  end

  @doc """
  Creates a music file.
  """
  def create_music_file(attrs \\ %{}) do
    %MusicFile{}
    |> MusicFile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a music file.
  """
  def update_music_file(%MusicFile{} = music_file, attrs) do
    music_file
    |> MusicFile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a music file.
  """
  def delete_music_file(%MusicFile{} = music_file) do
    Repo.delete(music_file)
  end

  ## Helper Functions

  defp apply_artist_filters(query, opts) do
    query
    |> filter_by_search(opts[:search], :name)
  end

  defp apply_album_filters(query, opts) do
    query
    |> filter_by_artist_id(opts[:artist_id])
    |> filter_by_monitored(opts[:monitored])
    |> filter_by_album_type(opts[:album_type])
    |> filter_by_search(opts[:search], :title)
  end

  defp apply_track_filters(query, opts) do
    query
    |> filter_by_album_id(opts[:album_id])
    |> filter_by_artist_id(opts[:artist_id])
  end

  defp apply_music_file_filters(query, opts) do
    query
    |> filter_by_track_id(opts[:track_id])
    |> filter_by_library_path_id(opts[:library_path_id])
  end

  defp filter_by_search(query, nil, _field), do: query

  defp filter_by_search(query, search, field) do
    search_term = "%#{search}%"
    where(query, [q], ilike(field(q, ^field), ^search_term))
  end

  defp filter_by_artist_id(query, nil), do: query
  defp filter_by_artist_id(query, artist_id), do: where(query, [q], q.artist_id == ^artist_id)

  defp filter_by_album_id(query, nil), do: query
  defp filter_by_album_id(query, album_id), do: where(query, [q], q.album_id == ^album_id)

  defp filter_by_track_id(query, nil), do: query
  defp filter_by_track_id(query, track_id), do: where(query, [q], q.track_id == ^track_id)

  defp filter_by_library_path_id(query, nil), do: query

  defp filter_by_library_path_id(query, library_path_id),
    do: where(query, [q], q.library_path_id == ^library_path_id)

  defp filter_by_monitored(query, nil), do: query
  defp filter_by_monitored(query, monitored), do: where(query, [q], q.monitored == ^monitored)

  defp filter_by_album_type(query, nil), do: query
  defp filter_by_album_type(query, album_type), do: where(query, [q], q.album_type == ^album_type)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: preload(query, ^preloads)
end
