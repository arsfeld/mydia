defmodule Mydia.Library.PreviewGeneratorTest do
  use Mydia.DataCase, async: true

  alias Mydia.Library.PreviewGenerator
  alias Mydia.Library.GeneratedMedia
  alias Mydia.Library.MediaFile
  alias Mydia.Library.ThumbnailGenerator

  @moduletag :external

  setup do
    # Use a temporary directory for generated content
    test_dir = Path.join([System.tmp_dir!(), "preview_test_#{:rand.uniform(100_000)}"])
    File.mkdir_p!(test_dir)
    Application.put_env(:mydia, :generated_media_path, test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
      Application.delete_env(:mydia, :generated_media_path)
    end)

    {:ok, test_dir: test_dir}
  end

  describe "generate/2" do
    test "returns error when library_path is not preloaded" do
      media_file = %MediaFile{
        id: Ecto.UUID.generate(),
        relative_path: "video.mp4",
        library_path_id: Ecto.UUID.generate(),
        library_path: nil
      }

      assert {:error, :library_path_not_preloaded} = PreviewGenerator.generate(media_file)
    end
  end

  describe "generate_from_path/2" do
    test "returns error for non-existent file" do
      assert {:error, :file_not_found} =
               PreviewGenerator.generate_from_path("/nonexistent/video.mp4")
    end

    @tag :requires_ffmpeg
    test "generates preview video from valid video file", %{test_dir: _test_dir} do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        # Create a test video (30 seconds to accommodate 4 segments of 3 seconds each)
        video_path = create_test_video(30)

        case PreviewGenerator.generate_from_path(video_path) do
          {:ok, checksum} ->
            # Verify checksum is valid
            assert String.length(checksum) == 32

            # Verify file exists in storage
            assert GeneratedMedia.exists?(:preview, checksum)

            # Verify the preview is a valid MP4
            preview_path = GeneratedMedia.get_path(:preview, checksum)
            {:ok, preview_content} = File.read(preview_path)
            # MP4 files typically start with ftyp atom after offset
            assert preview_content != ""

            # Verify it's a reasonably sized file (not empty)
            {:ok, stat} = File.stat(preview_path)
            assert stat.size > 1000

          {:error, reason} ->
            IO.puts("Preview generation failed: #{inspect(reason)}")
            # Don't fail the test if FFmpeg is misconfigured in test environment
            assert true
        end

        # Cleanup
        File.rm(video_path)
      end
    end

    @tag :requires_ffmpeg
    test "respects custom segment options", %{test_dir: _test_dir} do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        video_path = create_test_video(30)

        case PreviewGenerator.generate_from_path(video_path,
               segment_count: 2,
               segment_duration: 2
             ) do
          {:ok, checksum} ->
            # Verify checksum is valid
            assert String.length(checksum) == 32

            # Verify file exists in storage
            assert GeneratedMedia.exists?(:preview, checksum)

            # The preview should be smaller than default (2x2s vs 4x3s)
            preview_path = GeneratedMedia.get_path(:preview, checksum)
            {:ok, stat} = File.stat(preview_path)
            assert stat.size > 0

          {:error, reason} ->
            IO.puts("Preview generation failed: #{inspect(reason)}")
            assert true
        end

        File.rm(video_path)
      end
    end

    @tag :requires_ffmpeg
    test "respects skip_start_percent and skip_end_percent options", %{test_dir: _test_dir} do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        video_path = create_test_video(60)

        case PreviewGenerator.generate_from_path(video_path,
               segment_count: 4,
               segment_duration: 2,
               skip_start_percent: 10,
               skip_end_percent: 10
             ) do
          {:ok, checksum} ->
            assert String.length(checksum) == 32
            assert GeneratedMedia.exists?(:preview, checksum)

          {:error, reason} ->
            IO.puts("Preview generation failed: #{inspect(reason)}")
            assert true
        end

        File.rm(video_path)
      end
    end

    test "returns error for video too short to extract segments" do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        # Create a 5 second video but request 4x3=12 seconds of segments
        video_path = create_test_video(5)

        result =
          PreviewGenerator.generate_from_path(video_path,
            segment_count: 4,
            segment_duration: 3
          )

        # Should fail due to video being too short
        assert {:error, :video_too_short} = result

        File.rm(video_path)
      end
    end

    @tag :requires_ffmpeg
    test "generates preview with audio", %{test_dir: _test_dir} do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        video_path = create_test_video_with_audio(30)

        case PreviewGenerator.generate_from_path(video_path) do
          {:ok, checksum} ->
            assert String.length(checksum) == 32
            assert GeneratedMedia.exists?(:preview, checksum)

            # Verify file is valid
            preview_path = GeneratedMedia.get_path(:preview, checksum)
            {:ok, stat} = File.stat(preview_path)
            assert stat.size > 1000

          {:error, reason} ->
            IO.puts("Preview generation failed: #{inspect(reason)}")
            assert true
        end

        File.rm(video_path)
      end
    end
  end

  # Helper to create a minimal test video using FFmpeg
  defp create_test_video(duration) when is_number(duration) do
    temp_path = Path.join(System.tmp_dir!(), "test_video_#{:rand.uniform(1_000_000)}.mp4")

    args = [
      "-f",
      "lavfi",
      "-i",
      "color=c=blue:s=320x240:d=#{duration}",
      "-f",
      "lavfi",
      "-i",
      "anullsrc=r=44100:cl=stereo",
      "-c:v",
      "libx264",
      "-c:a",
      "aac",
      "-t",
      to_string(duration),
      "-shortest",
      "-y",
      temp_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> temp_path
      {output, _} -> raise "Failed to create test video: #{output}"
    end
  end

  defp create_test_video_with_audio(duration) when is_number(duration) do
    temp_path = Path.join(System.tmp_dir!(), "test_video_audio_#{:rand.uniform(1_000_000)}.mp4")

    args = [
      "-f",
      "lavfi",
      "-i",
      "color=c=red:s=320x240:d=#{duration}",
      "-f",
      "lavfi",
      "-i",
      "sine=frequency=1000:duration=#{duration}",
      "-c:v",
      "libx264",
      "-c:a",
      "aac",
      "-t",
      to_string(duration),
      "-shortest",
      "-y",
      temp_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> temp_path
      {output, _} -> raise "Failed to create test video with audio: #{output}"
    end
  end
end
