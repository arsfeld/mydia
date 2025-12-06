defmodule Mydia.Library.ThumbnailGenerator do
  @moduledoc """
  Generates thumbnail images and cover frames from video files using FFmpeg.

  This module provides functions to extract frames from video files at specified
  positions and save them as JPEG images. The generated thumbnails are stored
  using the GeneratedMedia content-addressable storage.

  ## Usage

      # Generate a cover image at 20% into the video (default)
      {:ok, checksum} = ThumbnailGenerator.generate_cover(media_file)

      # Generate at specific position (10 seconds)
      {:ok, checksum} = ThumbnailGenerator.generate_cover(media_file, position: {:seconds, 10})

      # Generate at specific percentage
      {:ok, checksum} = ThumbnailGenerator.generate_cover(media_file, position: {:percentage, 30})

  ## Requirements

  FFmpeg must be installed and available in the system PATH.
  """

  require Logger

  alias Mydia.Library.GeneratedMedia
  alias Mydia.Library.MediaFile

  @default_position {:percentage, 20}
  @default_quality 2
  @default_width 480

  @type position :: {:seconds, number()} | {:percentage, number()}
  @type generate_opts :: [
          position: position(),
          quality: integer(),
          width: integer()
        ]

  @doc """
  Generates a cover thumbnail from a video file.

  Extracts a single frame from the video at the specified position, converts it
  to JPEG, and stores it using GeneratedMedia storage.

  ## Parameters
    - `media_file` - The MediaFile struct (must have library_path preloaded)
    - `opts` - Optional settings:
      - `:position` - Where to extract the frame (default: `{:percentage, 20}`)
      - `:quality` - JPEG quality (1-31, lower is better, default: 2)
      - `:width` - Output width in pixels (height auto-scaled, default: 480)

  ## Returns
    - `{:ok, checksum}` - The MD5 checksum of the generated image
    - `{:error, reason}` - Error description

  ## Examples

      {:ok, checksum} = ThumbnailGenerator.generate_cover(media_file)
      {:ok, checksum} = ThumbnailGenerator.generate_cover(media_file, position: {:seconds, 30})
  """
  @spec generate_cover(MediaFile.t(), generate_opts()) :: {:ok, String.t()} | {:error, term()}
  def generate_cover(%MediaFile{} = media_file, opts \\ []) do
    input_path = MediaFile.absolute_path(media_file)

    if is_nil(input_path) do
      {:error, :library_path_not_preloaded}
    else
      do_generate_cover(input_path, opts)
    end
  end

  @doc """
  Generates a cover thumbnail from a file path.

  Same as `generate_cover/2` but takes a file path directly instead of a MediaFile.

  ## Parameters
    - `input_path` - Path to the video file
    - `opts` - Optional settings (see `generate_cover/2`)

  ## Returns
    - `{:ok, checksum}` - The MD5 checksum of the generated image
    - `{:error, reason}` - Error description
  """
  @spec generate_cover_from_path(Path.t(), generate_opts()) ::
          {:ok, String.t()} | {:error, term()}
  def generate_cover_from_path(input_path, opts \\ []) when is_binary(input_path) do
    if File.exists?(input_path) do
      do_generate_cover(input_path, opts)
    else
      {:error, :file_not_found}
    end
  end

  @doc """
  Gets the duration of a video file in seconds.

  Uses FFprobe to extract the video duration.

  ## Parameters
    - `input_path` - Path to the video file

  ## Returns
    - `{:ok, duration}` - Duration in seconds as a float
    - `{:error, reason}` - Error description
  """
  @spec get_duration(Path.t()) :: {:ok, float()} | {:error, term()}
  def get_duration(input_path) when is_binary(input_path) do
    args = [
      "-v",
      "error",
      "-show_entries",
      "format=duration",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      input_path
    ]

    case run_ffprobe(args) do
      {:ok, output} ->
        case Float.parse(String.trim(output)) do
          {duration, _} -> {:ok, duration}
          :error -> {:error, :invalid_duration}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Checks if FFmpeg is available on the system.

  ## Returns
    - `true` if FFmpeg is available
    - `false` otherwise
  """
  @spec ffmpeg_available?() :: boolean()
  def ffmpeg_available? do
    not is_nil(System.find_executable("ffmpeg"))
  end

  @doc """
  Checks if FFprobe is available on the system.

  ## Returns
    - `true` if FFprobe is available
    - `false` otherwise
  """
  @spec ffprobe_available?() :: boolean()
  def ffprobe_available? do
    not is_nil(System.find_executable("ffprobe"))
  end

  # Private implementation

  defp do_generate_cover(input_path, opts) do
    position = Keyword.get(opts, :position, @default_position)
    quality = Keyword.get(opts, :quality, @default_quality)
    width = Keyword.get(opts, :width, @default_width)

    with {:ok, seek_time} <- calculate_seek_time(input_path, position),
         {:ok, temp_path} <- create_temp_file(".jpg"),
         :ok <- run_ffmpeg_thumbnail(input_path, temp_path, seek_time, quality, width),
         {:ok, checksum} <- GeneratedMedia.store_file(:cover, temp_path) do
      # Clean up temp file
      File.rm(temp_path)
      {:ok, checksum}
    else
      {:error, reason} = error ->
        Logger.error("Failed to generate cover: #{inspect(reason)}")
        error
    end
  end

  defp calculate_seek_time(_input_path, {:seconds, seconds}) when is_number(seconds) do
    {:ok, seconds}
  end

  defp calculate_seek_time(input_path, {:percentage, percentage})
       when is_number(percentage) and percentage >= 0 and percentage <= 100 do
    case get_duration(input_path) do
      {:ok, duration} ->
        seek_time = duration * (percentage / 100)
        {:ok, seek_time}

      {:error, reason} ->
        # Fall back to a reasonable default if we can't get duration
        Logger.warning("Could not get video duration: #{inspect(reason)}, using 10s seek time")
        {:ok, 10.0}
    end
  end

  defp run_ffmpeg_thumbnail(input_path, output_path, seek_time, quality, width) do
    args = [
      "-ss",
      format_time(seek_time),
      "-i",
      input_path,
      "-vframes",
      "1",
      "-q:v",
      to_string(quality),
      "-vf",
      "scale=#{width}:-1",
      "-y",
      output_path
    ]

    case run_ffmpeg(args) do
      {:ok, _output} ->
        if File.exists?(output_path) do
          :ok
        else
          {:error, :output_not_created}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp run_ffmpeg(args) do
    ffmpeg = System.find_executable("ffmpeg")

    if is_nil(ffmpeg) do
      {:error, :ffmpeg_not_found}
    else
      case System.cmd(ffmpeg, args, stderr_to_stdout: true) do
        {output, 0} ->
          {:ok, output}

        {output, exit_code} ->
          Logger.debug("FFmpeg failed with exit code #{exit_code}: #{output}")
          {:error, {:ffmpeg_error, exit_code, output}}
      end
    end
  end

  defp run_ffprobe(args) do
    ffprobe = System.find_executable("ffprobe")

    if is_nil(ffprobe) do
      {:error, :ffprobe_not_found}
    else
      case System.cmd(ffprobe, args, stderr_to_stdout: true) do
        {output, 0} ->
          {:ok, output}

        {output, exit_code} ->
          Logger.debug("FFprobe failed with exit code #{exit_code}: #{output}")
          {:error, {:ffprobe_error, exit_code, output}}
      end
    end
  end

  defp format_time(seconds) when is_float(seconds) do
    hours = trunc(seconds / 3600)
    minutes = trunc(rem(trunc(seconds), 3600) / 60)
    secs = :erlang.float_to_binary(seconds - hours * 3600 - minutes * 60, decimals: 2)

    "#{pad_number(hours)}:#{pad_number(minutes)}:#{secs}"
  end

  defp format_time(seconds) when is_integer(seconds) do
    format_time(seconds * 1.0)
  end

  defp pad_number(n), do: String.pad_leading(to_string(n), 2, "0")

  defp create_temp_file(extension) do
    temp_dir = System.tmp_dir!()
    filename = "thumbnail_#{:rand.uniform(1_000_000_000)}#{extension}"
    path = Path.join(temp_dir, filename)
    {:ok, path}
  end
end
