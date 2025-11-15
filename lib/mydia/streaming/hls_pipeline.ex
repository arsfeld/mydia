defmodule Mydia.Streaming.HlsPipeline do
  @moduledoc """
  Membrane pipeline for transcoding video files to HLS format.

  This pipeline handles incompatible video files (HEVC, MKV, etc.) and converts them
  to browser-compatible H264/AAC HLS streams.

  ## Pipeline Flow

  ```
  File.Source
    → Demuxer (MP4 or Matroska based on container)
      → Video track → Decoder → SWScale → H264 Encoder → Parser
      → Audio track → Parser → AAC Decoder → SWResample → AAC Encoder
        → HLS SinkBin (combines both streams)
  ```

  ## Options

  * `:source_path` - Path to the source video file
  * `:output_dir` - Directory where HLS segments and playlists will be written
  * `:media_file` - MediaFile struct with codec information

  ## Streaming Modes

  The HLS SinkBin is configured with `mode: :live` for on-demand transcoding, which is
  appropriate for real-time streaming scenarios where segments are generated as the
  pipeline processes the file.

  The `hls_mode` defaults to `:separate_av` (separate audio/video playlists), which is
  recommended for most use cases as it provides better compatibility and flexibility.
  Use `:muxed_av` (single muxed playlist) only if you need a single stream for specific
  player requirements.
  """

  use Membrane.Pipeline

  require Membrane.Logger
  import Membrane.ChildrenSpec

  alias Membrane.{H264, H265, AAC, MP4, Matroska}
  alias Membrane.File.Source, as: FileSource
  alias Membrane.HTTPAdaptiveStream
  alias Membrane.FFmpeg.SWScale.Converter, as: SWScaleConverter
  alias Membrane.FFmpeg.SWResample.Converter, as: SWResampleConverter

  @impl true
  def handle_init(_ctx, opts) do
    source_path = Keyword.fetch!(opts, :source_path)
    output_dir = Keyword.fetch!(opts, :output_dir)
    media_file = Keyword.fetch!(opts, :media_file)

    # Ensure output directory exists
    File.mkdir_p!(output_dir)

    Membrane.Logger.info("Starting HLS transcoding pipeline for #{source_path}")
    Membrane.Logger.info("Output directory: #{output_dir}")
    Membrane.Logger.info("Source codec: #{media_file.codec}, audio: #{media_file.audio_codec}")

    # Build initial pipeline spec (source + demuxer + HLS sink)
    spec = build_initial_spec(source_path, output_dir, media_file)

    # Initialize state to track tracks and configuration
    state = %{
      output_dir: output_dir,
      media_file: media_file,
      video_linked: false,
      audio_linked: false
    }

    {[spec: spec], state}
  end

  @impl true
  def handle_child_notification({:new_track, {track_id, track_info}}, :demuxer, _ctx, state) do
    Membrane.Logger.info("Discovered track #{track_id}: #{inspect(track_info)}")

    case detect_track_type(track_info) do
      {:video, codec} when not state.video_linked ->
        Membrane.Logger.info("Track #{track_id} is video (#{codec})")
        spec = build_video_chain(track_id, codec)
        state = %{state | video_linked: true}
        {[spec: spec], state}

      {:audio, codec} when not state.audio_linked ->
        Membrane.Logger.info("Track #{track_id} is audio (#{codec})")
        spec = build_audio_chain(track_id, codec)
        state = %{state | audio_linked: true}
        {[spec: spec], state}

      {:video, _codec} ->
        Membrane.Logger.info("Skipping additional video track #{track_id} (already linked)")
        {[], state}

      {:audio, _codec} ->
        Membrane.Logger.info("Skipping additional audio track #{track_id} (already linked)")
        {[], state}

      :unsupported ->
        Membrane.Logger.warning("Track #{track_id} has unsupported codec: #{inspect(track_info)}")
        {[], state}
    end
  end

  def handle_child_notification(_notification, _child, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_element_end_of_stream(:hls_sink, :input, _ctx, state) do
    Membrane.Logger.info("HLS transcoding completed successfully")
    {[terminate: :normal], state}
  end

  def handle_element_end_of_stream(_element, _pad, _ctx, state) do
    {[], state}
  end

  # Build initial pipeline spec with source, demuxer, and HLS sink
  defp build_initial_spec(source_path, output_dir, media_file) do
    container = get_container_format(media_file)

    # Create demuxer based on container
    demuxer =
      if container in ["mkv", "webm"] do
        Matroska.Demuxer
      else
        MP4.Demuxer.ISOM
      end

    [
      child(:source, %FileSource{location: source_path})
      |> child(:demuxer, demuxer),

      # Create HLS sink upfront - tracks will connect to it dynamically
      child(:hls_sink, %HTTPAdaptiveStream.SinkBin{
        mode: :live,
        manifest_module: HTTPAdaptiveStream.HLS,
        target_window_duration: Membrane.Time.seconds(30),
        storage: %HTTPAdaptiveStream.Storages.FileStorage{directory: output_dir}
      })
    ]
  end

  # Detect track type from track info
  defp detect_track_type(%{codec: codec})
       when codec in ["h264", "avc1", "hevc", "hev1", "h265", "vp8", "vp9"] do
    {:video, normalize_video_codec(codec)}
  end

  defp detect_track_type(%{codec: codec}) when codec in ["aac", "opus", "mp3"] do
    {:audio, normalize_audio_codec(codec)}
  end

  defp detect_track_type(_track_info) do
    :unsupported
  end

  # Normalize video codec names
  defp normalize_video_codec(codec) when codec in ["hevc", "hev1", "h265"], do: :hevc
  defp normalize_video_codec(codec) when codec in ["h264", "avc1"], do: :h264
  defp normalize_video_codec(codec), do: String.to_atom(codec)

  # Normalize audio codec names
  defp normalize_audio_codec(codec) when codec in ["aac"], do: :aac
  defp normalize_audio_codec(codec), do: String.to_atom(codec)

  # Build video transcoding chain and link to HLS sink
  defp build_video_chain(track_id, codec) do
    video_decoder = get_video_decoder_module(codec)
    segment_duration = Membrane.Time.seconds(6)

    [
      get_child(:demuxer)
      |> via_out(Pad.ref(:output, track_id))
      |> child(:video_decoder, video_decoder)
      |> child(:video_scaler, %SWScaleConverter{
        output_width: 1280,
        output_height: 720,
        format: :I420
      })
      |> child(:video_encoder, %H264.FFmpeg.Encoder{
        preset: :medium,
        profile: :high,
        max_b_frames: 0,
        gop_size: 60
      })
      |> child(:video_parser, H264.Parser)
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: segment_duration, track_name: "video"]
      )
      |> get_child(:hls_sink)
    ]
  end

  # Build audio transcoding chain and link to HLS sink
  defp build_audio_chain(track_id, codec) do
    audio_decoder = get_audio_decoder_module(codec)
    segment_duration = Membrane.Time.seconds(6)

    [
      get_child(:demuxer)
      |> via_out(Pad.ref(:output, track_id))
      |> child(:audio_parser, AAC.Parser)
      |> child(:audio_decoder, audio_decoder)
      |> child(:audio_resampler, %SWResampleConverter{
        output_stream_format: %Membrane.RawAudio{
          sample_format: :s16le,
          sample_rate: 48_000,
          channels: 2
        }
      })
      |> child(:audio_encoder, %AAC.FDK.Encoder{
        aot: :mpeg4_lc,
        bitrate: 128_000,
        bitrate_mode: 0
      })
      |> via_in(Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: segment_duration, track_name: "audio"]
      )
      |> get_child(:hls_sink)
    ]
  end

  # Get video decoder module based on codec
  defp get_video_decoder_module(:hevc), do: H265.FFmpeg.Decoder
  defp get_video_decoder_module(:h264), do: H264.FFmpeg.Decoder
  defp get_video_decoder_module(_), do: H264.FFmpeg.Decoder

  # Get audio decoder module based on codec
  defp get_audio_decoder_module(:aac), do: AAC.FDK.Decoder
  defp get_audio_decoder_module(:opus), do: raise("Opus decoder not yet supported")
  defp get_audio_decoder_module(_), do: AAC.FDK.Decoder

  # Extract container format from metadata or file path
  defp get_container_format(media_file) do
    case media_file.metadata do
      %{"container" => container} when is_binary(container) ->
        String.downcase(container)

      %{"format_name" => format_name} when is_binary(format_name) ->
        format_name
        |> String.split(",")
        |> List.first()
        |> String.trim()
        |> String.downcase()

      _ ->
        # Use relative_path for file extension detection
        media_file.relative_path
        |> Path.extname()
        |> String.trim_leading(".")
        |> String.downcase()
    end
  end
end
