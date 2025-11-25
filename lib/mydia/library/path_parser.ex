defmodule Mydia.Library.PathParser do
  @moduledoc """
  Parses folder structure to extract TV show name and season information.

  For files in structured TV library paths like `/media/tv/{Show Name}/Season {XX}/`,
  this module prioritizes folder structure over filename parsing for show identification.

  ## Why Folder Structure Matters

  Many media files have non-standard filenames that don't match their actual content:
  - `Playdate 2025 2160p AMZN WEB-DL...` (in Bluey folder - wrong filename)
  - `Robin.Hood.2025.S01E01...` (in Robin Hood folder - year causes issues)
  - `One-Punch.Man.S03E04...` vs `One.Punch.Man.S03E02...` (inconsistent naming)

  When files are organized in standard TV library structure, the folder name is
  authoritative and should be used for metadata matching.

  ## Folder Patterns Recognized

  Show name folder patterns:
  - `/media/tv/The Office/...` → "The Office"
  - `/media/tv/One-Punch Man/...` → "One-Punch Man"

  Season folder patterns:
  - `Season 01` → season 1
  - `Season 1` → season 1
  - `S01` → season 1
  - `Season.01` → season 1
  - `Specials` → season 0
  """

  require Logger

  # Define season patterns as a function to avoid module attribute compilation issues
  defp season_patterns do
    [
      # "Season 01", "Season 1", "Season.01", "Season.1"
      ~r/^Season[\s._-]?0?(\d{1,2})$/i,
      # "S01", "S1"
      ~r/^S0?(\d{1,2})$/i,
      # "Specials" - treated as season 0
      ~r/^Specials?$/i
    ]
  end

  defp specials_pattern, do: ~r/^Specials?$/i

  @doc """
  Extracts show name and season number from a file path.

  Returns a map with `:show_name` and `:season` keys if folder structure
  indicates a TV show path, or nil if no TV structure is detected.

  ## Examples

      iex> PathParser.extract_from_path("/media/tv/The Office/Season 02/episode.mkv")
      %{show_name: "The Office", season: 2}

      iex> PathParser.extract_from_path("/media/tv/Bluey/Season 03/Playdate 2025.mkv")
      %{show_name: "Bluey", season: 3}

      iex> PathParser.extract_from_path("/downloads/random_file.mkv")
      nil
  """
  @spec extract_from_path(String.t()) :: %{show_name: String.t(), season: integer() | nil} | nil
  def extract_from_path(path) when is_binary(path) do
    # Split path into segments
    segments = path |> Path.split() |> Enum.reject(&(&1 == "/" || &1 == ""))

    # We need at least 3 segments: parent/show_name/season/file or parent/show_name/file
    # Minimum: something/show_name/file.mkv
    if length(segments) < 2 do
      nil
    else
      # Get the directory path (remove filename)
      dir_segments = Enum.drop(segments, -1)

      # Try to find a season folder and show name folder
      case find_tv_structure(dir_segments) do
        {:ok, show_name, season} ->
          Logger.debug("Extracted TV structure from path",
            path: path,
            show_name: show_name,
            season: season
          )

          %{show_name: show_name, season: season}

        :error ->
          nil
      end
    end
  end

  def extract_from_path(_), do: nil

  @doc """
  Checks if a folder name matches a season pattern.

  ## Examples

      iex> PathParser.parse_season_folder("Season 01")
      {:ok, 1}

      iex> PathParser.parse_season_folder("S03")
      {:ok, 3}

      iex> PathParser.parse_season_folder("Specials")
      {:ok, 0}

      iex> PathParser.parse_season_folder("The Office")
      :error
  """
  @spec parse_season_folder(String.t()) :: {:ok, integer()} | :error
  def parse_season_folder(folder_name) when is_binary(folder_name) do
    Enum.find_value(season_patterns(), :error, fn pattern ->
      case Regex.run(pattern, folder_name) do
        # Specials pattern (no capture group)
        [_match] ->
          # Check if this is the specials pattern
          if Regex.match?(specials_pattern(), folder_name) do
            {:ok, 0}
          else
            nil
          end

        # Season number patterns
        [_match, season_str] ->
          {:ok, String.to_integer(season_str)}

        nil ->
          nil
      end
    end)
  end

  def parse_season_folder(_), do: :error

  @doc """
  Checks if a path appears to be a TV show library path.

  Returns true if the path contains a recognizable TV show folder structure.

  ## Examples

      iex> PathParser.is_tv_path?("/media/tv/The Office/Season 01/episode.mkv")
      true

      iex> PathParser.is_tv_path?("/downloads/Movie.2020.1080p.mkv")
      false
  """
  @spec is_tv_path?(String.t()) :: boolean()
  def is_tv_path?(path) when is_binary(path) do
    extract_from_path(path) != nil
  end

  def is_tv_path?(_), do: false

  # Private helpers

  # Finds TV structure by looking for season folder and inferring show name
  defp find_tv_structure(dir_segments) do
    # Work backwards through segments to find the season folder
    dir_segments
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.find_value(:error, fn {segment, index} ->
      case parse_season_folder(segment) do
        {:ok, season} ->
          # Found a season folder - the show name should be the segment before it
          if index > 0 do
            show_name = Enum.at(dir_segments, index - 1)

            # Validate show name is reasonable (not a root folder like "media" or "tv")
            if valid_show_name?(show_name) do
              {:ok, show_name, season}
            else
              nil
            end
          else
            nil
          end

        :error ->
          nil
      end
    end)
  end

  # Validates that a folder name is likely a show name and not a system/root folder
  defp valid_show_name?(name) when is_binary(name) do
    # Reject common root folder names
    root_folders =
      ~w(media tv shows series television video videos library content data home usr mnt)

    normalized = String.downcase(name)

    # Show name should:
    # - Not be a common root folder
    # - Be at least 2 characters
    # - Not start with a dot (hidden folders)
    normalized not in root_folders &&
      String.length(name) >= 2 &&
      not String.starts_with?(name, ".")
  end

  defp valid_show_name?(_), do: false
end
