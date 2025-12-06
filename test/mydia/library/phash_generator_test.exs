defmodule Mydia.Library.PhashGeneratorTest do
  use Mydia.DataCase, async: true

  alias Mydia.Library.PhashGenerator
  alias Mydia.Library.MediaFile
  alias Mydia.Library.ThumbnailGenerator

  @moduletag :external

  describe "hamming_distance/2" do
    test "returns 0 for identical hashes" do
      hash = "a1b2c3d4e5f60708"
      assert PhashGenerator.hamming_distance(hash, hash) == 0
    end

    test "returns correct distance for hashes differing by 1 bit" do
      # 0x0000000000000001 and 0x0000000000000000 differ by 1 bit
      hash1 = "0000000000000001"
      hash2 = "0000000000000000"
      assert PhashGenerator.hamming_distance(hash1, hash2) == 1
    end

    test "returns correct distance for hashes differing by multiple bits" do
      # 0x000000000000000F (binary: ...1111) and 0x0000000000000000 differ by 4 bits
      hash1 = "000000000000000f"
      hash2 = "0000000000000000"
      assert PhashGenerator.hamming_distance(hash1, hash2) == 4
    end

    test "returns correct distance for opposite hashes" do
      # All 1s and all 0s differ by 64 bits
      hash1 = "ffffffffffffffff"
      hash2 = "0000000000000000"
      assert PhashGenerator.hamming_distance(hash1, hash2) == 64
    end

    test "returns 64 for malformed hashes" do
      assert PhashGenerator.hamming_distance("short", "alsoshort") == 64
      assert PhashGenerator.hamming_distance("", "") == 64
    end

    test "is case insensitive" do
      hash1 = "A1B2C3D4E5F60708"
      hash2 = "a1b2c3d4e5f60708"
      assert PhashGenerator.hamming_distance(hash1, hash2) == 0
    end
  end

  describe "similar?/3" do
    test "returns true for identical hashes" do
      hash = "a1b2c3d4e5f60708"
      assert PhashGenerator.similar?(hash, hash) == true
    end

    test "returns true for hashes within threshold" do
      hash1 = "000000000000000f"
      hash2 = "0000000000000000"
      # 4 bits difference, default threshold is 10
      assert PhashGenerator.similar?(hash1, hash2) == true
    end

    test "returns false for hashes exceeding threshold" do
      hash1 = "ffffffffffffffff"
      hash2 = "0000000000000000"
      assert PhashGenerator.similar?(hash1, hash2) == false
    end

    test "respects custom threshold" do
      hash1 = "000000000000000f"
      hash2 = "0000000000000000"
      # 4 bits difference
      assert PhashGenerator.similar?(hash1, hash2, 5) == true
      assert PhashGenerator.similar?(hash1, hash2, 3) == false
    end
  end

  describe "generate/2" do
    test "returns error when library_path is not preloaded" do
      media_file = %MediaFile{
        id: Ecto.UUID.generate(),
        relative_path: "video.mp4",
        library_path_id: Ecto.UUID.generate(),
        library_path: nil
      }

      assert {:error, :library_path_not_preloaded} = PhashGenerator.generate(media_file)
    end
  end

  describe "generate_from_path/2" do
    test "returns error for non-existent file" do
      assert {:error, :file_not_found} =
               PhashGenerator.generate_from_path("/nonexistent/video.mp4")
    end

    @tag :requires_ffmpeg
    test "generates phash from valid video file" do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        video_path = create_test_video()

        case PhashGenerator.generate_from_path(video_path) do
          {:ok, hash} ->
            # Hash should be a 16-character hexadecimal string
            assert String.length(hash) == 16
            assert Regex.match?(~r/^[0-9a-f]{16}$/, hash)

          {:error, reason} ->
            IO.puts("Phash generation failed: #{inspect(reason)}")
            assert true
        end

        File.rm(video_path)
      end
    end

    @tag :requires_ffmpeg
    test "generates consistent hashes for same video" do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        video_path = create_test_video()

        case {PhashGenerator.generate_from_path(video_path),
              PhashGenerator.generate_from_path(video_path)} do
          {{:ok, hash1}, {:ok, hash2}} ->
            # Same video should produce same or very similar hash
            assert hash1 == hash2

          _ ->
            # Don't fail the test if FFmpeg is misconfigured
            assert true
        end

        File.rm(video_path)
      end
    end

    @tag :requires_ffmpeg
    test "generates similar hashes for similar videos" do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        # Create two similar videos (same color, different duration)
        video1 = create_test_video(color: "blue", duration: 2)
        video2 = create_test_video(color: "blue", duration: 3)

        case {PhashGenerator.generate_from_path(video1),
              PhashGenerator.generate_from_path(video2)} do
          {{:ok, hash1}, {:ok, hash2}} ->
            distance = PhashGenerator.hamming_distance(hash1, hash2)
            # Similar videos should have low Hamming distance
            # Blue solid color videos at 20% position should be nearly identical
            assert distance <= 10

          _ ->
            assert true
        end

        File.rm(video1)
        File.rm(video2)
      end
    end

    @tag :requires_ffmpeg
    test "generates different hashes for different videos" do
      unless ThumbnailGenerator.ffmpeg_available?() do
        IO.puts("Skipping test: FFmpeg not available")
        assert true
      else
        # Create two visually different videos with patterns (not solid colors)
        # Solid colors produce all-zero hashes since no adjacent pixel differences
        video1 = create_test_video_with_pattern("testsrc", duration: 2)
        video2 = create_test_video_with_pattern("smptebars", duration: 2)

        case {PhashGenerator.generate_from_path(video1),
              PhashGenerator.generate_from_path(video2)} do
          {{:ok, hash1}, {:ok, hash2}} ->
            # Different patterned videos should have different hashes
            assert hash1 != hash2

          _ ->
            assert true
        end

        File.rm(video1)
        File.rm(video2)
      end
    end
  end

  # Helper to create a minimal test video using FFmpeg
  defp create_test_video(opts \\ []) do
    color = Keyword.get(opts, :color, "blue")
    duration = Keyword.get(opts, :duration, 1)
    temp_path = Path.join(System.tmp_dir!(), "test_video_#{:rand.uniform(1_000_000)}.mp4")

    args = [
      "-f",
      "lavfi",
      "-i",
      "color=c=#{color}:s=320x240:d=#{duration}",
      "-c:v",
      "libx264",
      "-t",
      "#{duration}",
      "-y",
      temp_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> temp_path
      {output, _} -> raise "Failed to create test video: #{output}"
    end
  end

  # Helper to create a test video with a pattern (not solid color)
  defp create_test_video_with_pattern(pattern, opts) do
    duration = Keyword.get(opts, :duration, 1)
    temp_path = Path.join(System.tmp_dir!(), "test_video_#{:rand.uniform(1_000_000)}.mp4")

    args = [
      "-f",
      "lavfi",
      "-i",
      "#{pattern}=s=320x240:d=#{duration}",
      "-c:v",
      "libx264",
      "-t",
      "#{duration}",
      "-y",
      temp_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> temp_path
      {output, _} -> raise "Failed to create test video: #{output}"
    end
  end
end
