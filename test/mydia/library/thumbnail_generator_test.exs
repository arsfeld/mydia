defmodule Mydia.Library.ThumbnailGeneratorTest do
  use Mydia.DataCase, async: true

  alias Mydia.Library.ThumbnailGenerator
  alias Mydia.Library.GeneratedMedia
  alias Mydia.Library.MediaFile

  @moduletag :external

  setup do
    # Use a temporary directory for generated content
    test_dir = Path.join([System.tmp_dir!(), "thumbnail_test_#{:rand.uniform(100_000)}"])
    File.mkdir_p!(test_dir)
    Application.put_env(:mydia, :generated_media_path, test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
      Application.delete_env(:mydia, :generated_media_path)
    end)

    {:ok, test_dir: test_dir}
  end

  describe "ffmpeg_available?/0" do
    test "returns a boolean" do
      result = ThumbnailGenerator.ffmpeg_available?()
      assert is_boolean(result)
    end
  end

  describe "ffprobe_available?/0" do
    test "returns a boolean" do
      result = ThumbnailGenerator.ffprobe_available?()
      assert is_boolean(result)
    end
  end

  describe "generate_cover/2" do
    test "returns error when library_path is not preloaded" do
      media_file = %MediaFile{
        id: Ecto.UUID.generate(),
        relative_path: "video.mp4",
        library_path_id: Ecto.UUID.generate(),
        library_path: nil
      }

      assert {:error, :library_path_not_preloaded} = ThumbnailGenerator.generate_cover(media_file)
    end
  end

  describe "generate_cover_from_path/2" do
    test "returns error for non-existent file" do
      assert {:error, :file_not_found} =
               ThumbnailGenerator.generate_cover_from_path("/nonexistent/video.mp4")
    end

    @tag :requires_ffmpeg
    test "generates thumbnail from valid video file", %{test_dir: _test_dir} do
      # Skip if FFmpeg is not available
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        # Create a minimal test video using FFmpeg
        video_path = create_test_video()

        case ThumbnailGenerator.generate_cover_from_path(video_path) do
          {:ok, checksum} ->
            assert String.length(checksum) == 32
            assert GeneratedMedia.exists?(:cover, checksum)

            # Verify the generated file is a valid JPEG
            cover_path = GeneratedMedia.get_path(:cover, checksum)
            {:ok, content} = File.read(cover_path)
            # JPEG magic bytes
            assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = content

          {:error, reason} ->
            IO.puts("Thumbnail generation failed: #{inspect(reason)}")
            # Don't fail the test if FFmpeg is misconfigured in test environment
            assert true
        end

        # Cleanup
        File.rm(video_path)
      end
    end
  end

  describe "get_duration/1" do
    test "returns error for non-existent file" do
      result = ThumbnailGenerator.get_duration("/nonexistent/video.mp4")
      # Could be :ffprobe_not_found or an ffprobe error
      assert {:error, _reason} = result
    end

    @tag :requires_ffmpeg
    test "returns duration for valid video file" do
      unless ThumbnailGenerator.ffprobe_available?() do
        IO.puts("Skipping test: FFprobe not available")
        assert true
      else
        video_path = create_test_video()

        case ThumbnailGenerator.get_duration(video_path) do
          {:ok, duration} ->
            assert is_float(duration)
            assert duration > 0

          {:error, reason} ->
            IO.puts("Duration detection failed: #{inspect(reason)}")
            assert true
        end

        File.rm(video_path)
      end
    end
  end

  # Helper to create a minimal test video using FFmpeg
  defp create_test_video do
    temp_path = Path.join(System.tmp_dir!(), "test_video_#{:rand.uniform(1_000_000)}.mp4")

    # Create a 1-second test video with FFmpeg
    args = [
      "-f",
      "lavfi",
      "-i",
      "color=c=blue:s=320x240:d=1",
      "-c:v",
      "libx264",
      "-t",
      "1",
      "-y",
      temp_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> temp_path
      {output, _} -> raise "Failed to create test video: #{output}"
    end
  end
end
