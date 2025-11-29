defmodule Mydia.LibraryItem.Album do
  @moduledoc """
  LibraryItem implementation for Album (music albums).
  """
  @behaviour Mydia.LibraryItem

  @default_cover "/images/no-poster.svg"

  @impl Mydia.LibraryItem
  def display_title(%Mydia.Music.Album{title: title}), do: title

  @impl Mydia.LibraryItem
  def poster_url(%Mydia.Music.Album{cover_url: cover_url}) do
    if is_binary(cover_url) and cover_url != "" do
      cover_url
    else
      @default_cover
    end
  end

  @impl Mydia.LibraryItem
  def item_path(%Mydia.Music.Album{id: id}) do
    "/music/albums/#{id}"
  end

  @impl Mydia.LibraryItem
  def metadata_badges(%Mydia.Music.Album{} = album) do
    badges = []

    # Add album type badge
    type_badge =
      case album.album_type do
        "album" -> %{label: "Album", class: "badge-info"}
        "single" -> %{label: "Single", class: "badge-secondary"}
        "ep" -> %{label: "EP", class: "badge-secondary"}
        "compilation" -> %{label: "Compilation", class: "badge-warning"}
        _ -> nil
      end

    if type_badge, do: [type_badge | badges], else: badges
  end

  @impl Mydia.LibraryItem
  def file_size(%Mydia.Music.Album{tracks: tracks}) when is_list(tracks) do
    tracks
    |> Enum.flat_map(fn track ->
      case track.music_files do
        files when is_list(files) -> files
        _ -> []
      end
    end)
    |> Enum.map(& &1.size)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  def file_size(_), do: 0

  @impl Mydia.LibraryItem
  def year(%Mydia.Music.Album{release_date: nil}), do: nil

  def year(%Mydia.Music.Album{release_date: release_date}) do
    release_date.year
  end

  @impl Mydia.LibraryItem
  def item_type(%Mydia.Music.Album{}), do: "album"

  @impl Mydia.LibraryItem
  def monitored?(%Mydia.Music.Album{monitored: monitored}), do: monitored

  @impl Mydia.LibraryItem
  def quality_badge(%Mydia.Music.Album{tracks: tracks}) when is_list(tracks) do
    # Get highest bitrate from tracks
    bitrate =
      tracks
      |> Enum.flat_map(fn track ->
        case track.music_files do
          files when is_list(files) -> files
          _ -> []
        end
      end)
      |> Enum.map(& &1.bitrate)
      |> Enum.reject(&is_nil/1)
      |> Enum.max(fn -> nil end)

    format_bitrate(bitrate)
  end

  def quality_badge(_), do: nil

  @impl Mydia.LibraryItem
  def secondary_text(%Mydia.Music.Album{artist: artist}) when not is_nil(artist) do
    case artist do
      %Mydia.Music.Artist{name: name} -> name
      _ -> nil
    end
  end

  def secondary_text(_), do: nil

  @impl Mydia.LibraryItem
  def status(%Mydia.Music.Album{} = album) do
    # For now, simple status based on whether files exist
    track_count = get_track_count(album)
    file_count = get_file_count(album)

    cond do
      file_count == 0 ->
        {:missing, %{downloaded: 0, total: track_count}}

      file_count < track_count ->
        {:partial, %{downloaded: file_count, total: track_count}}

      true ->
        {:complete, %{downloaded: file_count, total: track_count}}
    end
  end

  defp get_track_count(%Mydia.Music.Album{total_tracks: total}) when is_integer(total), do: total

  defp get_track_count(%Mydia.Music.Album{tracks: tracks}) when is_list(tracks),
    do: length(tracks)

  defp get_track_count(_), do: 0

  defp get_file_count(%Mydia.Music.Album{tracks: tracks}) when is_list(tracks) do
    tracks
    |> Enum.flat_map(fn track ->
      case track.music_files do
        files when is_list(files) -> files
        _ -> []
      end
    end)
    |> length()
  end

  defp get_file_count(_), do: 0

  defp format_bitrate(nil), do: nil
  defp format_bitrate(bitrate) when bitrate >= 320, do: "320kbps"
  defp format_bitrate(bitrate) when bitrate >= 256, do: "256kbps"
  defp format_bitrate(bitrate) when bitrate >= 192, do: "192kbps"
  defp format_bitrate(bitrate) when bitrate >= 128, do: "128kbps"
  defp format_bitrate(bitrate), do: "#{bitrate}kbps"
end
