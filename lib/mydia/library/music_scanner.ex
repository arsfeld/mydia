defmodule Mydia.Library.MusicScanner do
  @moduledoc """
  Scans and processes music files in library paths.

  Handles:
  - Scanning for music files (.mp3, .flac, .wav, etc.)
  - Extracting metadata from audio tags (ID3, FLAC tags)
  - Creating Artist, Album, Track, and MusicFile records
  - Matching files to existing library items
  """

  require Logger

  alias Mydia.{Music, Repo}
  alias Mydia.Music.{Artist, Album, Track}
  alias Mydia.Library.Scanner
  alias Mydia.Settings.LibraryPath

  @doc """
  Processes scan results for a music library path.

  Takes the raw scan result and creates/updates music records in the database.
  """
  def process_scan_result(%LibraryPath{} = library_path, scan_result) do
    existing_files = Music.list_music_files(library_path_id: library_path.id)

    # Detect changes using the shared scanner logic
    changes = Scanner.detect_changes(scan_result, existing_files, library_path)

    Logger.info("Processing music library changes",
      new_files: length(changes.new_files),
      modified_files: length(changes.modified_files),
      deleted_files: length(changes.deleted_files)
    )

    # Process new files
    new_results = Enum.map(changes.new_files, &process_new_file(&1, library_path))

    # Process modified files (re-read metadata)
    Enum.each(changes.modified_files, &process_modified_file(&1, library_path))

    # Delete removed files
    Enum.each(changes.deleted_files, &delete_music_file/1)

    %{
      new_files: length(changes.new_files),
      modified_files: length(changes.modified_files),
      deleted_files: length(changes.deleted_files),
      new_results: new_results
    }
  end

  @doc """
  Extracts metadata from an audio file using FFprobe.

  Returns metadata including artist, album, title, track number, duration, etc.
  """
  def extract_metadata(file_path) do
    args = [
      "-v",
      "quiet",
      "-print_format",
      "json",
      "-show_format",
      "-show_streams",
      file_path
    ]

    case System.cmd("ffprobe", args, stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, data} ->
            {:ok, parse_audio_metadata(data, file_path)}

          {:error, _} ->
            {:error, :invalid_json}
        end

      {_, _exit_code} ->
        {:error, :ffprobe_failed}
    end
  rescue
    ErlangError ->
      {:error, :ffprobe_not_found}
  end

  ## Private Functions

  defp process_new_file(file_info, library_path) do
    relative_path = Path.relative_to(file_info.path, library_path.path)

    case extract_metadata(file_info.path) do
      {:ok, metadata} ->
        # Find or create artist
        artist = find_or_create_artist(metadata)

        # Find or create album
        album = find_or_create_album(metadata, artist)

        # Find or create track
        track = find_or_create_track(metadata, album, artist)

        # Create music file record
        case create_music_file(file_info, relative_path, library_path, track, metadata) do
          {:ok, music_file} ->
            Logger.debug("Created music file record",
              path: relative_path,
              artist: metadata.artist,
              album: metadata.album,
              title: metadata.title
            )

            {:ok, music_file}

          {:error, changeset} ->
            Logger.error("Failed to create music file",
              path: relative_path,
              errors: inspect(changeset.errors)
            )

            {:error, changeset}
        end

      {:error, reason} ->
        # Create orphaned music file (no metadata extracted)
        Logger.warning("Could not extract metadata from music file",
          path: file_info.path,
          reason: reason
        )

        create_orphaned_music_file(file_info, relative_path, library_path)
    end
  end

  defp process_modified_file(file_info, library_path) do
    relative_path = Path.relative_to(file_info.path, library_path.path)

    case Music.get_music_file_by_path(file_info.path) do
      nil ->
        # File was somehow not in DB, process as new
        process_new_file(file_info, library_path)

      music_file ->
        # Update size and potentially re-read metadata
        case extract_metadata(file_info.path) do
          {:ok, metadata} ->
            Music.update_music_file(music_file, %{
              size: file_info.size,
              bitrate: metadata.bitrate,
              sample_rate: metadata.sample_rate,
              channels: metadata.channels,
              codec: metadata.codec,
              duration: metadata.duration
            })

          {:error, _} ->
            # Just update size
            Music.update_music_file(music_file, %{size: file_info.size})
        end

        Logger.debug("Updated music file", path: relative_path)
    end
  end

  defp delete_music_file(music_file) do
    case Music.delete_music_file(music_file) do
      {:ok, _} ->
        Logger.debug("Deleted music file record", id: music_file.id)

      {:error, reason} ->
        Logger.error("Failed to delete music file",
          id: music_file.id,
          reason: inspect(reason)
        )
    end
  end

  defp find_or_create_artist(metadata) do
    artist_name = metadata.artist || "Unknown Artist"

    # Try to find existing artist by name
    case find_artist_by_name(artist_name) do
      nil ->
        {:ok, artist} =
          Music.create_artist(%{
            name: artist_name,
            sort_name: generate_sort_name(artist_name)
          })

        artist

      artist ->
        artist
    end
  end

  defp find_artist_by_name(name) do
    import Ecto.Query

    Artist
    |> where([a], fragment("LOWER(?)", a.name) == ^String.downcase(name))
    |> Repo.one()
  end

  defp find_or_create_album(metadata, artist) do
    album_title = metadata.album || "Unknown Album"

    # Try to find existing album by title and artist
    case find_album_by_title_and_artist(album_title, artist.id) do
      nil ->
        {:ok, album} =
          Music.create_album(%{
            title: album_title,
            artist_id: artist.id,
            release_date: parse_release_date(metadata.date),
            genres: parse_genres(metadata.genre),
            total_tracks: metadata.track_total
          })

        album

      album ->
        album
    end
  end

  defp find_album_by_title_and_artist(title, artist_id) do
    import Ecto.Query

    Album
    |> where([a], a.artist_id == ^artist_id)
    |> where([a], fragment("LOWER(?)", a.title) == ^String.downcase(title))
    |> Repo.one()
  end

  defp find_or_create_track(metadata, album, artist) do
    track_title =
      metadata.title || Path.basename(metadata.filename, Path.extname(metadata.filename))

    track_number = metadata.track_number || 1
    disc_number = metadata.disc_number || 1

    # Try to find existing track by album and track number
    case find_track_by_album_and_number(album.id, disc_number, track_number) do
      nil ->
        {:ok, track} =
          Music.create_track(%{
            title: track_title,
            album_id: album.id,
            artist_id: artist.id,
            track_number: track_number,
            disc_number: disc_number,
            duration: metadata.duration
          })

        track

      track ->
        # Update title if we now have better metadata
        if track.title != track_title do
          {:ok, updated} = Music.update_track(track, %{title: track_title})
          updated
        else
          track
        end
    end
  end

  defp find_track_by_album_and_number(album_id, disc_number, track_number) do
    import Ecto.Query

    Track
    |> where([t], t.album_id == ^album_id)
    |> where([t], t.disc_number == ^disc_number)
    |> where([t], t.track_number == ^track_number)
    |> Repo.one()
  end

  defp create_music_file(file_info, relative_path, library_path, track, metadata) do
    Music.create_music_file(%{
      path: file_info.path,
      relative_path: relative_path,
      size: file_info.size,
      library_path_id: library_path.id,
      track_id: track.id,
      bitrate: metadata.bitrate,
      sample_rate: metadata.sample_rate,
      codec: metadata.codec,
      channels: metadata.channels,
      duration: metadata.duration
    })
  end

  defp create_orphaned_music_file(file_info, relative_path, library_path) do
    Music.create_music_file(%{
      path: file_info.path,
      relative_path: relative_path,
      size: file_info.size,
      library_path_id: library_path.id
      # track_id is nil - orphaned file
    })
  end

  defp parse_audio_metadata(data, file_path) do
    format = Map.get(data, "format", %{})
    tags = Map.get(format, "tags", %{})
    streams = Map.get(data, "streams", [])
    audio_stream = Enum.find(streams, fn s -> s["codec_type"] == "audio" end)

    # Tags can have various cases (TITLE, title, Title)
    normalized_tags = normalize_tags(tags)

    %{
      # Core metadata from tags
      title: normalized_tags["title"],
      artist: normalized_tags["artist"] || normalized_tags["album_artist"],
      album: normalized_tags["album"],
      album_artist: normalized_tags["album_artist"] || normalized_tags["artist"],
      genre: normalized_tags["genre"],
      date: normalized_tags["date"] || normalized_tags["year"],
      track_number: parse_track_number(normalized_tags["track"]),
      track_total: parse_track_total(normalized_tags["track"]),
      disc_number: parse_disc_number(normalized_tags["disc"]),
      disc_total: parse_disc_total(normalized_tags["disc"]),

      # Technical metadata
      duration: parse_duration(format["duration"]),
      bitrate: parse_bitrate(audio_stream, format),
      sample_rate: audio_stream && parse_int(audio_stream["sample_rate"]),
      channels: audio_stream && audio_stream["channels"],
      codec: extract_audio_codec(audio_stream),

      # File info
      filename: Path.basename(file_path)
    }
  end

  defp normalize_tags(tags) do
    tags
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> Map.new()
  end

  defp parse_track_number(nil), do: nil

  defp parse_track_number(track) when is_binary(track) do
    # Handle "1/12" or "01" format
    track
    |> String.split("/")
    |> List.first()
    |> parse_int()
  end

  defp parse_track_number(track) when is_integer(track), do: track

  defp parse_track_total(nil), do: nil

  defp parse_track_total(track) when is_binary(track) do
    case String.split(track, "/") do
      [_, total] -> parse_int(total)
      _ -> nil
    end
  end

  defp parse_track_total(_), do: nil

  defp parse_disc_number(nil), do: 1

  defp parse_disc_number(disc) when is_binary(disc) do
    disc
    |> String.split("/")
    |> List.first()
    |> parse_int()
    |> case do
      nil -> 1
      n -> n
    end
  end

  defp parse_disc_number(disc) when is_integer(disc), do: disc

  defp parse_disc_total(nil), do: nil

  defp parse_disc_total(disc) when is_binary(disc) do
    case String.split(disc, "/") do
      [_, total] -> parse_int(total)
      _ -> nil
    end
  end

  defp parse_disc_total(_), do: nil

  defp parse_duration(nil), do: nil

  defp parse_duration(duration) when is_binary(duration) do
    case Float.parse(duration) do
      {seconds, _} -> round(seconds)
      :error -> nil
    end
  end

  defp parse_duration(duration) when is_number(duration), do: round(duration)

  defp parse_bitrate(nil, format), do: parse_int(format["bit_rate"])
  defp parse_bitrate(stream, _format), do: parse_int(stream["bit_rate"])

  defp parse_int(nil), do: nil
  defp parse_int(value) when is_integer(value), do: value

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp extract_audio_codec(nil), do: nil

  defp extract_audio_codec(stream) do
    case stream["codec_name"] do
      "mp3" -> "MP3"
      "aac" -> "AAC"
      "flac" -> "FLAC"
      "opus" -> "Opus"
      "vorbis" -> "Vorbis"
      "alac" -> "ALAC"
      "ape" -> "APE"
      "wav" -> "WAV"
      "pcm_s16le" -> "PCM"
      "pcm_s24le" -> "PCM 24-bit"
      "pcm_s32le" -> "PCM 32-bit"
      name when is_binary(name) -> String.upcase(name)
      _ -> nil
    end
  end

  defp generate_sort_name(name) do
    # Remove common prefixes for sorting
    name
    |> String.trim()
    |> String.replace(~r/^(The|A|An)\s+/i, "")
  end

  defp parse_release_date(nil), do: nil

  defp parse_release_date(date) when is_binary(date) do
    cond do
      # Full date: 2023-01-15
      String.match?(date, ~r/^\d{4}-\d{2}-\d{2}$/) ->
        case Date.from_iso8601(date) do
          {:ok, d} -> d
          _ -> nil
        end

      # Year only: 2023
      String.match?(date, ~r/^\d{4}$/) ->
        case Integer.parse(date) do
          {year, _} -> Date.new!(year, 1, 1)
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp parse_release_date(_), do: nil

  defp parse_genres(nil), do: []

  defp parse_genres(genre) when is_binary(genre) do
    genre
    |> String.split(~r/[,;\/]/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_genres(_), do: []
end
