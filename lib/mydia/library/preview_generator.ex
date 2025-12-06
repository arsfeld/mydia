defmodule Mydia.Library.PreviewGenerator do
  @moduledoc """
  Generates short preview video clips from video files using FFmpeg.

  This module extracts multiple segments from different parts of a video,
  concatenates them into a single preview video, and stores the result
  using the GeneratedMedia content-addressable storage.

  ## Usage

      # Generate a preview video with default settings
      {:ok, checksum} = PreviewGenerator.generate(media_file)

      # Generate with custom options
      {:ok, checksum} = PreviewGenerator.generate(media_file,
        segment_count: 6,           # Number of segments to extract
        segment_duration: 2,        # Duration of each segment in seconds
        skip_start_percent: 10,     # Skip first 10% of video
        skip_end_percent: 10        # Skip last 10% of video
      )

  ## Output Format

  The preview is an MP4 video composed of short segments from different
  parts of the source video. By default, it creates a 12-second preview
  (4 segments × 3 seconds each).

  ## Requirements

  FFmpeg must be installed and available in the system PATH.
  """

  require Logger

  alias Mydia.Library.GeneratedMedia
  alias Mydia.Library.MediaFile
  alias Mydia.Library.ThumbnailGenerator

  @default_segment_count 4
  @default_segment_duration 3
  @default_skip_start_percent 5
  @default_skip_end_percent 5
  @default_output_width 640
  @default_output_height 360
  @default_video_bitrate "1M"
  @default_audio_bitrate "128k"

  @type generate_opts :: [
          segment_count: pos_integer(),
          segment_duration: pos_integer(),
          skip_start_percent: number(),
          skip_end_percent: number(),
          output_width: pos_integer(),
          output_height: pos_integer(),
          video_bitrate: String.t(),
          audio_bitrate: String.t()
        ]

  @doc """
  Generates a preview video from a media file.

  Extracts multiple segments from evenly-spaced positions in the video,
  concatenates them, and stores the result using GeneratedMedia storage.

  ## Parameters
    - `media_file` - The MediaFile struct (must have library_path preloaded)
    - `opts` - Optional settings:
      - `:segment_count` - Number of segments to extract (default: #{@default_segment_count})
      - `:segment_duration` - Duration of each segment in seconds (default: #{@default_segment_duration})
      - `:skip_start_percent` - Percentage of video to skip at start (default: #{@default_skip_start_percent})
      - `:skip_end_percent` - Percentage of video to skip at end (default: #{@default_skip_end_percent})
      - `:output_width` - Output video width (default: #{@default_output_width})
      - `:output_height` - Output video height (default: #{@default_output_height})
      - `:video_bitrate` - Video bitrate (default: #{@default_video_bitrate})
      - `:audio_bitrate` - Audio bitrate (default: #{@default_audio_bitrate})

  ## Returns
    - `{:ok, checksum}` - The MD5 checksum of the generated preview
    - `{:error, reason}` - Error description

  ## Examples

      {:ok, checksum} = PreviewGenerator.generate(media_file)
      {:ok, checksum} = PreviewGenerator.generate(media_file, segment_count: 6, segment_duration: 2)
  """
  @spec generate(MediaFile.t(), generate_opts()) :: {:ok, String.t()} | {:error, term()}
  def generate(%MediaFile{} = media_file, opts \\ []) do
    input_path = MediaFile.absolute_path(media_file)

    if is_nil(input_path) do
      {:error, :library_path_not_preloaded}
    else
      do_generate(input_path, opts)
    end
  end

  @doc """
  Generates a preview video from a file path.

  Same as `generate/2` but takes a file path directly instead of a MediaFile.
  """
  @spec generate_from_path(Path.t(), generate_opts()) :: {:ok, String.t()} | {:error, term()}
  def generate_from_path(input_path, opts \\ []) when is_binary(input_path) do
    if File.exists?(input_path) do
      do_generate(input_path, opts)
    else
      {:error, :file_not_found}
    end
  end

  # Private implementation

  defp do_generate(input_path, opts) do
    segment_count = Keyword.get(opts, :segment_count, @default_segment_count)
    segment_duration = Keyword.get(opts, :segment_duration, @default_segment_duration)
    skip_start_percent = Keyword.get(opts, :skip_start_percent, @default_skip_start_percent)
    skip_end_percent = Keyword.get(opts, :skip_end_percent, @default_skip_end_percent)
    output_width = Keyword.get(opts, :output_width, @default_output_width)
    output_height = Keyword.get(opts, :output_height, @default_output_height)
    video_bitrate = Keyword.get(opts, :video_bitrate, @default_video_bitrate)
    audio_bitrate = Keyword.get(opts, :audio_bitrate, @default_audio_bitrate)

    with {:ok, duration} <- ThumbnailGenerator.get_duration(input_path),
         {:ok, timestamps} <-
           calculate_segment_timestamps(
             duration,
             segment_count,
             segment_duration,
             skip_start_percent,
             skip_end_percent
           ),
         {:ok, temp_dir} <- create_temp_directory(),
         {:ok, segment_paths} <-
           extract_segments(
             input_path,
             timestamps,
             segment_duration,
             temp_dir,
             output_width,
             output_height,
             video_bitrate,
             audio_bitrate
           ),
         {:ok, output_path} <- concatenate_segments(segment_paths, temp_dir),
         {:ok, checksum} <- GeneratedMedia.store_file(:preview, output_path) do
      cleanup_temp_directory(temp_dir)
      {:ok, checksum}
    else
      {:error, reason} = error ->
        Logger.error("Failed to generate preview video: #{inspect(reason)}")
        error
    end
  end

  defp calculate_segment_timestamps(
         duration,
         segment_count,
         segment_duration,
         skip_start_percent,
         skip_end_percent
       ) do
    # Calculate effective range
    effective_start = duration * (skip_start_percent / 100)
    effective_end = duration * (1 - skip_end_percent / 100)
    effective_duration = effective_end - effective_start

    # Check if there's enough time for all segments
    total_segment_time = segment_count * segment_duration

    if effective_duration < total_segment_time do
      {:error, :video_too_short}
    else
      # Calculate evenly-spaced positions for segments
      # We want to space them evenly across the effective duration
      available_duration = effective_duration - total_segment_time
      gap = available_duration / segment_count

      timestamps =
        0..(segment_count - 1)
        |> Enum.map(fn i ->
          # Position each segment at: effective_start + gap/2 + i*(gap + segment_duration)
          effective_start + gap / 2 + i * (gap + segment_duration)
        end)

      {:ok, timestamps}
    end
  end

  defp extract_segments(
         input_path,
         timestamps,
         segment_duration,
         temp_dir,
         output_width,
         output_height,
         video_bitrate,
         audio_bitrate
       ) do
    results =
      timestamps
      |> Enum.with_index()
      |> Enum.map(fn {timestamp, index} ->
        output_path =
          Path.join(temp_dir, "segment_#{String.pad_leading(to_string(index), 3, "0")}.mp4")

        extract_single_segment(
          input_path,
          timestamp,
          segment_duration,
          output_path,
          output_width,
          output_height,
          video_bitrate,
          audio_bitrate
        )
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if errors == [] do
      {:ok, Enum.map(results, fn {:ok, path} -> path end)}
    else
      {:error, {:segment_extraction_failed, errors}}
    end
  end

  defp extract_single_segment(
         input_path,
         timestamp,
         duration,
         output_path,
         output_width,
         output_height,
         video_bitrate,
         audio_bitrate
       ) do
    args = [
      "-ss",
      format_time(timestamp),
      "-i",
      input_path,
      "-t",
      to_string(duration),
      "-vf",
      "scale=#{output_width}:#{output_height}:force_original_aspect_ratio=decrease,pad=#{output_width}:#{output_height}:(ow-iw)/2:(oh-ih)/2,setsar=1",
      "-c:v",
      "libx264",
      "-preset",
      "fast",
      "-b:v",
      video_bitrate,
      "-c:a",
      "aac",
      "-b:a",
      audio_bitrate,
      "-movflags",
      "+faststart",
      "-y",
      output_path
    ]

    case run_ffmpeg(args) do
      {:ok, _output} ->
        if File.exists?(output_path) do
          {:ok, output_path}
        else
          {:error, {:segment_not_created, timestamp}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp concatenate_segments(segment_paths, temp_dir) do
    # Create a concat demuxer file listing all segments
    concat_list_path = Path.join(temp_dir, "concat_list.txt")

    concat_content =
      segment_paths
      |> Enum.map(&"file '#{&1}'")
      |> Enum.join("\n")

    File.write!(concat_list_path, concat_content)

    output_path = Path.join(temp_dir, "preview.mp4")

    # Use concat demuxer for lossless concatenation
    args = [
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      concat_list_path,
      "-c",
      "copy",
      "-movflags",
      "+faststart",
      "-y",
      output_path
    ]

    case run_ffmpeg(args) do
      {:ok, _output} ->
        if File.exists?(output_path) do
          {:ok, output_path}
        else
          {:error, :concatenation_failed}
        end

      {:error, reason} ->
        {:error, reason}
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

  defp create_temp_directory do
    temp_dir = Path.join(System.tmp_dir!(), "preview_#{:rand.uniform(1_000_000_000)}")

    case File.mkdir_p(temp_dir) do
      :ok -> {:ok, temp_dir}
      {:error, reason} -> {:error, reason}
    end
  end

  defp cleanup_temp_directory(temp_dir) do
    File.rm_rf(temp_dir)
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
end
