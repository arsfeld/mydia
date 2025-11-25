defmodule Mydia.Library.PathParserTest do
  use ExUnit.Case, async: true

  alias Mydia.Library.PathParser

  describe "extract_from_path/1" do
    test "extracts show name and season from standard TV structure" do
      result = PathParser.extract_from_path("/media/tv/The Office/Season 02/episode.mkv")

      assert result == %{show_name: "The Office", season: 2}
    end

    test "extracts show name with hyphen" do
      result = PathParser.extract_from_path("/media/tv/One-Punch Man/Season 03/episode.mkv")

      assert result == %{show_name: "One-Punch Man", season: 3}
    end

    test "handles Season with single digit" do
      result = PathParser.extract_from_path("/media/tv/Bluey/Season 1/episode.mkv")

      assert result == %{show_name: "Bluey", season: 1}
    end

    test "handles Season with leading zero" do
      result = PathParser.extract_from_path("/media/tv/Severance/Season 01/episode.mkv")

      assert result == %{show_name: "Severance", season: 1}
    end

    test "handles S01 folder format" do
      result = PathParser.extract_from_path("/media/tv/Robin Hood/S01/episode.mkv")

      assert result == %{show_name: "Robin Hood", season: 1}
    end

    test "handles Season.XX format with dot" do
      result = PathParser.extract_from_path("/media/tv/Show Name/Season.02/episode.mkv")

      assert result == %{show_name: "Show Name", season: 2}
    end

    test "handles Season-XX format with dash" do
      result = PathParser.extract_from_path("/media/tv/Show Name/Season-03/episode.mkv")

      assert result == %{show_name: "Show Name", season: 3}
    end

    test "handles Specials folder as season 0" do
      result = PathParser.extract_from_path("/media/tv/Doctor Who/Specials/special.mkv")

      assert result == %{show_name: "Doctor Who", season: 0}
    end

    test "handles deep path structure" do
      result =
        PathParser.extract_from_path(
          "/home/user/media/library/television/The Mandalorian/Season 02/episode.mkv"
        )

      assert result == %{show_name: "The Mandalorian", season: 2}
    end

    test "returns nil for flat file structure" do
      result = PathParser.extract_from_path("/downloads/random_file.mkv")

      assert result == nil
    end

    test "returns nil for movie-like structure" do
      result = PathParser.extract_from_path("/media/movies/Inception (2010)/movie.mkv")

      assert result == nil
    end

    test "returns nil for file without enough path segments" do
      result = PathParser.extract_from_path("/file.mkv")

      assert result == nil
    end

    test "returns nil for non-binary input" do
      assert PathParser.extract_from_path(nil) == nil
      assert PathParser.extract_from_path(123) == nil
    end

    test "ignores common root folders as show names" do
      result = PathParser.extract_from_path("/media/Season 01/episode.mkv")

      assert result == nil
    end

    test "ignores tv as show name" do
      result = PathParser.extract_from_path("/tv/Season 01/episode.mkv")

      assert result == nil
    end
  end

  describe "parse_season_folder/1" do
    test "parses Season 01" do
      assert PathParser.parse_season_folder("Season 01") == {:ok, 1}
    end

    test "parses Season 1" do
      assert PathParser.parse_season_folder("Season 1") == {:ok, 1}
    end

    test "parses Season.05" do
      assert PathParser.parse_season_folder("Season.05") == {:ok, 5}
    end

    test "parses Season-10" do
      assert PathParser.parse_season_folder("Season-10") == {:ok, 10}
    end

    test "parses S01" do
      assert PathParser.parse_season_folder("S01") == {:ok, 1}
    end

    test "parses S1" do
      assert PathParser.parse_season_folder("S1") == {:ok, 1}
    end

    test "parses Specials as season 0" do
      assert PathParser.parse_season_folder("Specials") == {:ok, 0}
    end

    test "parses Special (singular) as season 0" do
      assert PathParser.parse_season_folder("Special") == {:ok, 0}
    end

    test "returns error for non-season folder" do
      assert PathParser.parse_season_folder("The Office") == :error
    end

    test "returns error for random text" do
      assert PathParser.parse_season_folder("random") == :error
    end

    test "returns error for non-binary input" do
      assert PathParser.parse_season_folder(nil) == :error
    end

    test "handles case insensitive matching" do
      assert PathParser.parse_season_folder("season 01") == {:ok, 1}
      assert PathParser.parse_season_folder("SEASON 01") == {:ok, 1}
      assert PathParser.parse_season_folder("s01") == {:ok, 1}
    end
  end

  describe "is_tv_path?/1" do
    test "returns true for TV show path" do
      assert PathParser.is_tv_path?("/media/tv/Show Name/Season 01/episode.mkv") == true
    end

    test "returns false for movie path" do
      assert PathParser.is_tv_path?("/media/movies/Movie (2020)/movie.mkv") == false
    end

    test "returns false for downloads path" do
      assert PathParser.is_tv_path?("/downloads/random.mkv") == false
    end

    test "returns false for non-binary input" do
      assert PathParser.is_tv_path?(nil) == false
    end
  end

  describe "real-world examples from task-265" do
    test "extracts Bluey from folder even with wrong filename" do
      # This file has "Playdate 2025" in the filename but is in Bluey folder
      result =
        PathParser.extract_from_path(
          "/media/tv/Bluey/Season 03/Playdate 2025 2160p AMZN WEB-DL.mkv"
        )

      assert result == %{show_name: "Bluey", season: 3}
    end

    test "extracts Bluey from folder with completely wrong show in filename" do
      # This file has "Naruto Gaiden" in the filename but is in Bluey folder
      result =
        PathParser.extract_from_path("/media/tv/Bluey/Season 02/Naruto Gaiden 1A S02E01 720p.mkv")

      assert result == %{show_name: "Bluey", season: 2}
    end

    test "extracts Robin Hood from folder" do
      result =
        PathParser.extract_from_path(
          "/media/tv/Robin Hood/Season 01/Robin.Hood.2025.S01E01.720p.mkv"
        )

      assert result == %{show_name: "Robin Hood", season: 1}
    end

    test "extracts Severance from folder" do
      result =
        PathParser.extract_from_path("/media/tv/Severance/Season 01/Severance.S01E08.mkv")

      assert result == %{show_name: "Severance", season: 1}
    end

    test "extracts One-Punch Man from folder" do
      result =
        PathParser.extract_from_path("/media/tv/One-Punch Man/Season 03/One-Punch.Man.S03E04.mkv")

      assert result == %{show_name: "One-Punch Man", season: 3}
    end
  end
end
