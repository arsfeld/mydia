defmodule Mydia.Downloads.TorrentParser do
  @moduledoc """
  Parses torrent names to extract structured media information.

  Includes pre-validation to reject invalid/fake releases before parsing.

  ## Parsing Process

  1. **Validation**: Check for known bad patterns (hashed releases, password-protected, etc.)
  2. **Cleaning**: Remove tracker prefixes and normalize the name
  3. **Type Detection**: Determine if movie, TV episode, or season pack
  4. **Extraction**: Parse title, year, quality, source, codec, and release group

  ## Supported Formats

  Handles common torrent naming patterns for movies and TV shows to extract:
  - Title
  - Year (for movies)
  - Season and episode numbers (for TV shows)
  - Season packs (full seasons without episode numbers)
  - Quality/resolution
  - Release group
  - Edition (Director's Cut, Extended Edition, etc. - for movies)

  Supports complex torrent names with:
  - Website/tracker prefixes (e.g., [bitsearch.to], 【高清剧集网】)
  - Multiple bracket types containing metadata
  - Mixed Chinese and English titles
  - Chinese season markers (第6季, 第四季)
  - Language and subtitle indicators

  ## Examples

      iex> parse("The.Matrix.1999.1080p.BluRay.x264-SPARKS")
      {:ok, %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: "1080p",
        source: "BluRay",
        codec: "x264",
        release_group: "SPARKS"
      }}

      iex> parse("Breaking.Bad.S01E01.720p.HDTV.x264-CTU")
      {:ok, %{
        type: :tv,
        title: "Breaking Bad",
        season: 1,
        episode: 1,
        quality: "720p",
        source: "HDTV",
        codec: "x264",
        release_group: "CTU"
      }}

      iex> parse("House.of.the.Dragon.S01.COMPLETE.2160p.BluRay.x265-GROUP")
      {:ok, %{
        type: :tv_season,
        title: "House of the Dragon",
        season: 1,
        season_pack: true,
        quality: "2160p",
        source: "BluRay",
        codec: "x265",
        release_group: "GROUP"
      }}
  """

  alias Mydia.Downloads.ReleaseValidator

  @doc """
  Parses a torrent name and returns structured information.

  First validates the release name to reject known bad patterns,
  then attempts to parse the type and extract metadata.

  Returns `{:ok, info_map}` on success, or `{:error, reason}` if parsing fails.

  ## Error Reasons

  - `:hashed_release` - Contains obfuscated hex string
  - `:numeric_only_title` - Title has no meaningful text
  - `:password_protected` - Requires password
  - `:reversed_pattern` - Non-standard naming pattern
  - `:yenc_pattern` - Raw usenet binary encoding
  - `:no_meaningful_content` - No extractable title
  - `:unable_to_parse` - Doesn't match known formats
  """
  def parse(name) when is_binary(name) do
    # Validate release name before parsing
    case ReleaseValidator.validate_release(name) do
      {:ok, valid_name} ->
        parse_validated_release(valid_name)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_validated_release(name) do
    name = clean_name(name)

    cond do
      # Try to parse as TV show (check for season/episode pattern)
      tv_info = parse_tv(name) ->
        {:ok, tv_info}

      # Try to parse as movie (check for year pattern)
      movie_info = parse_movie(name) ->
        {:ok, movie_info}

      # Unable to determine type
      true ->
        {:error, :unable_to_parse}
    end
  end

  ## Private Functions

  defp clean_name(name) do
    # Remove file extensions if present
    name
    |> String.replace(~r/\.(mkv|mp4|avi|mov|wmv|flv|webm)$/i, "")
    |> strip_prefixes()
    |> String.trim()
  end

  defp strip_prefixes(name) do
    name
    # Remove ALL Chinese brackets with content (e.g., 【高清剧集网 www.BTHDTV.com】)
    # These appear throughout the name, not just at the start
    |> String.replace(~r/【[^】]*】\s*/u, "")
    # Remove ALL square brackets with content (metadata, website tags, etc.)
    # e.g., [47BT], [Ex-torrenty.org], [全9集], [简繁英字幕]
    |> String.replace(~r/\[[^\]]+\]\s*/u, "")
    # Remove ALL curly braces with content
    |> String.replace(~r/\{[^\}]+\}\s*/u, "")
    # Clean up any Chinese season/episode markers like "第6季", "第四季"
    # These often appear before the English title and confuse matching
    |> String.replace(~r/第\d+季\s*/u, "")
    |> String.replace(~r/第[一二三四五六七八九十]+季\s*/u, "")
    # Trim any remaining leading/trailing whitespace
    |> String.trim()
  end

  defp parse_tv(name) do
    # Match patterns like S01E01, S1E1, 1x01, etc.
    cond do
      # S01E01 or S1E1 format
      match =
          Regex.named_captures(
            ~r/^(?<title>.+?)[\s\.]S(?<season>\d{1,2})E(?<episode>\d{1,2})/i,
            name
          ) ->
        build_tv_info(match, name)

      # 1x01 format
      match =
          Regex.named_captures(
            ~r/^(?<title>.+?)[\s\.](?<season>\d{1,2})x(?<episode>\d{1,2})/i,
            name
          ) ->
        build_tv_info(match, name)

      # Season pack format: S01, S1, etc. (no episode number)
      match =
          Regex.named_captures(
            ~r/^(?<title>.+?)[\s\.]S(?<season>\d{1,2})[\s\.\-]/i,
            name
          ) ->
        build_season_pack_info(match, name)

      true ->
        nil
    end
  end

  defp build_tv_info(match, full_name) do
    title = clean_title(match["title"])
    season = String.to_integer(match["season"])
    episode = String.to_integer(match["episode"])

    # Extract remaining parts after the episode marker
    remaining = extract_remaining_after_episode(full_name, match)

    %{
      type: :tv,
      title: title,
      season: season,
      episode: episode,
      quality: extract_quality(remaining),
      source: extract_source(remaining),
      codec: extract_codec(remaining),
      release_group: extract_release_group(remaining)
    }
  end

  defp build_season_pack_info(match, full_name) do
    title = clean_title(match["title"])
    season = String.to_integer(match["season"])

    # Extract remaining parts after the season marker
    remaining = extract_remaining_after_season(full_name, match)

    %{
      type: :tv_season,
      title: title,
      season: season,
      season_pack: true,
      quality: extract_quality(remaining),
      source: extract_source(remaining),
      codec: extract_codec(remaining),
      release_group: extract_release_group(remaining)
    }
  end

  defp parse_movie(name) do
    # Match patterns with year: Title (2020) or Title.2020
    case Regex.named_captures(
           ~r/^(?<title>.+?)[\s\.\(\[](?<year>19\d{2}|20\d{2})[\s\.\)\]]/i,
           name
         ) do
      nil ->
        nil

      match ->
        title = clean_title(match["title"])
        year = String.to_integer(match["year"])

        # Extract remaining parts after the year
        remaining = extract_remaining_after_year(name, match)

        %{
          type: :movie,
          title: title,
          year: year,
          quality: extract_quality(remaining),
          source: extract_source(remaining),
          codec: extract_codec(remaining),
          release_group: extract_release_group(remaining),
          edition: extract_edition(remaining)
        }
    end
  end

  defp clean_title(title) do
    title
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.trim()
    # Remove common language codes and noise words from the end of titles
    |> remove_trailing_noise()
    # Normalize multiple spaces
    |> String.replace(~r/\s+/, " ")
  end

  defp remove_trailing_noise(title) do
    # Remove common language codes and noise at the end of titles
    # E.g., "Naruto ITA JPN" -> "Naruto"
    # Common patterns: MULTi, ITA, JPN, ENG, FRA, GER, SPA, etc.
    title
    |> String.replace(
      ~r/\s+(MULTi|ITA|JPN|ENG|FRA|GER|SPA|POR|RUS|CHN|KOR|DUAL|COMPLETE|Reencode|Rebuild)\b.*$/i,
      ""
    )
    |> String.trim()
  end

  defp extract_remaining_after_episode(full_name, match) do
    # Find where the episode pattern ends
    pattern = "S#{match["season"]}E#{match["episode"]}"

    case String.split(full_name, pattern, parts: 2) do
      [_, remaining] -> remaining
      _ -> ""
    end
  end

  defp extract_remaining_after_season(full_name, match) do
    # Find where the season pattern ends
    # Need to handle case-insensitive matching
    season_str =
      String.to_integer(match["season"]) |> Integer.to_string() |> String.pad_leading(2, "0")

    cond do
      # Try with S## format (uppercase)
      remaining = extract_after_pattern(full_name, "S#{season_str}") ->
        remaining

      # Try with s## format (lowercase)
      remaining = extract_after_pattern(full_name, "s#{season_str}") ->
        remaining

      # Try single digit
      remaining = extract_after_pattern(full_name, "S#{match["season"]}") ->
        remaining

      true ->
        ""
    end
  end

  defp extract_after_pattern(full_name, pattern) do
    case String.split(full_name, pattern, parts: 2) do
      [_, remaining] -> remaining
      _ -> nil
    end
  end

  defp extract_remaining_after_year(full_name, match) do
    # Find where the year ends
    year = match["year"]

    case String.split(full_name, year, parts: 2) do
      [_, remaining] -> remaining
      _ -> ""
    end
  end

  defp extract_quality(text) do
    cond do
      Regex.match?(~r/2160p|4K/i, text) -> "2160p"
      Regex.match?(~r/1080p/i, text) -> "1080p"
      Regex.match?(~r/720p/i, text) -> "720p"
      Regex.match?(~r/480p/i, text) -> "480p"
      Regex.match?(~r/\bSD\b/i, text) -> "SD"
      true -> nil
    end
  end

  defp extract_source(text) do
    cond do
      Regex.match?(~r/BluRay|Blu-Ray|BDRip|BRRip/i, text) -> "BluRay"
      Regex.match?(~r/WEB-?DL|WEBDL/i, text) -> "WEB-DL"
      Regex.match?(~r/WEBRip|WEB-?Rip/i, text) -> "WEBRip"
      Regex.match?(~r/HDTV/i, text) -> "HDTV"
      Regex.match?(~r/DVDRip/i, text) -> "DVDRip"
      Regex.match?(~r/DVD/i, text) -> "DVD"
      true -> nil
    end
  end

  defp extract_codec(text) do
    cond do
      Regex.match?(~r/x265|h\.?265|HEVC/i, text) -> "x265"
      Regex.match?(~r/x264|h\.?264/i, text) -> "x264"
      Regex.match?(~r/XviD/i, text) -> "XviD"
      true -> nil
    end
  end

  defp extract_release_group(text) do
    # Release group is typically after a dash at the end
    # e.g., "-SPARKS" or "[SPARKS]"
    case Regex.run(~r/[-\[]([A-Z0-9]+)[\]\s]*$/i, text) do
      [_, group] -> group
      _ -> nil
    end
  end

  defp extract_edition(text) do
    # Detect various edition types
    # Order matters - check more specific patterns first
    cond do
      # Director's Cut variants
      Regex.match?(~r/Director'?s?.?(Cut|Edition)/i, text) ->
        "Director's Cut"

      # Extended variants
      Regex.match?(~r/Extended.?(Cut|Edition|Version)/i, text) ->
        "Extended Edition"

      # Theatrical variants
      Regex.match?(~r/Theatrical.?(Cut|Release|Edition|Version)/i, text) ->
        "Theatrical"

      # Ultimate Edition
      Regex.match?(~r/Ultimate.?(Edition|Cut)/i, text) ->
        "Ultimate Edition"

      # Collector's Edition
      Regex.match?(~r/Collector'?s?.?Edition/i, text) ->
        "Collector's Edition"

      # Special Edition
      Regex.match?(~r/Special.?Edition/i, text) ->
        "Special Edition"

      # Unrated
      Regex.match?(~r/\bUnrated\b/i, text) ->
        "Unrated"

      # Remastered
      Regex.match?(~r/\bRemastered\b/i, text) ->
        "Remastered"

      # IMAX Edition
      Regex.match?(~r/\bIMAX\b/i, text) ->
        "IMAX"

      # No edition detected
      true ->
        nil
    end
  end
end
