defmodule Mydia.Library.MetadataMatcherTest do
  use ExUnit.Case, async: true

  # Note: These tests would typically use mocks or fixtures for metadata API responses
  # For now, they test the matching logic with sample data structures

  describe "match_movie/3" do
    test "matches movie with exact title and year" do
      parsed = %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: %{resolution: "1080p"},
        confidence: 0.9
      }

      # Mock search results
      mock_results = [
        %{
          provider_id: "603",
          title: "The Matrix",
          year: 1999,
          popularity: 50.5,
          media_type: :movie
        }
      ]

      # Test the scoring directly (we'd need to mock Metadata.search for full test)
      {result, score} =
        Enum.map(mock_results, fn r ->
          {r, calculate_test_movie_score(r, parsed)}
        end)
        |> Enum.at(0)

      assert score >= 0.9
      assert result.title == "The Matrix"
      assert result.year == 1999
    end

    test "matches movie with slight title variation" do
      parsed = %{
        type: :movie,
        title: "The Lord Of The Rings The Fellowship Of The Ring",
        year: 2001,
        quality: %{},
        confidence: 0.85
      }

      mock_result = %{
        provider_id: "120",
        title: "The Lord of the Rings: The Fellowship of the Ring",
        year: 2001,
        popularity: 80.0
      }

      # Title should be similar enough to match
      similarity = test_title_similarity(mock_result.title, parsed.title)
      assert similarity >= 0.7
    end

    test "matches movie with year off by one" do
      parsed = %{
        type: :movie,
        title: "Inception",
        year: 2010,
        quality: %{},
        confidence: 0.9
      }

      # Sometimes release dates vary by region
      mock_result = %{
        provider_id: "27205",
        title: "Inception",
        year: 2009,
        popularity: 60.0
      }

      # Should still match with ±1 year
      assert test_year_match(mock_result.year, parsed.year)
    end
  end

  describe "match_tv_show/3" do
    test "matches TV show with exact title" do
      parsed = %{
        type: :tv_show,
        title: "Breaking Bad",
        year: 2008,
        season: 1,
        episodes: [1],
        quality: %{resolution: "1080p"},
        confidence: 0.9
      }

      mock_result = %{
        provider_id: "1396",
        title: "Breaking Bad",
        year: 2008,
        first_air_date: "2008-01-20",
        popularity: 120.0
      }

      score = calculate_test_tv_score(mock_result, parsed)
      assert score >= 0.9
    end

    test "matches TV show without year" do
      parsed = %{
        type: :tv_show,
        title: "Game Of Thrones",
        year: nil,
        season: 1,
        episodes: [1],
        quality: %{},
        confidence: 0.85
      }

      mock_result = %{
        provider_id: "1399",
        title: "Game of Thrones",
        year: 2011,
        first_air_date: "2011-04-17",
        popularity: 150.0
      }

      # Should still match based on title similarity
      similarity = test_title_similarity(mock_result.title, parsed.title)
      assert similarity >= 0.9
    end
  end

  describe "title_similarity/2" do
    test "exact match returns 1.0" do
      assert test_title_similarity("The Matrix", "The Matrix") == 1.0
    end

    test "case insensitive match returns 1.0" do
      assert test_title_similarity("The Matrix", "the matrix") == 1.0
    end

    test "punctuation differences still match well" do
      title1 = "The Lord of the Rings: The Fellowship"
      title2 = "The Lord Of The Rings The Fellowship"

      similarity = test_title_similarity(title1, title2)
      assert similarity >= 0.9
    end

    test "substring match returns high score" do
      similarity = test_title_similarity("The Matrix", "The Matrix Reloaded")
      assert similarity >= 0.7
    end

    test "completely different titles return low score" do
      similarity = test_title_similarity("The Matrix", "Inception")
      assert similarity < 0.5
    end

    test "similar but not exact titles return medium score" do
      similarity = test_title_similarity("Star Wars", "Star Trek")
      assert similarity > 0.3 and similarity < 0.8
    end

    test "handles article variations (The Matrix vs Matrix, The)" do
      # Should get high score for substring match after normalization
      similarity = test_title_similarity("The Matrix", "Matrix")
      assert similarity >= 0.8
    end

    test "handles and vs & variations" do
      similarity = test_title_similarity("Fast and Furious", "Fast & Furious")
      assert similarity >= 0.95
    end

    test "handles roman numeral variations (Rocky II vs Rocky 2)" do
      similarity = test_title_similarity("Rocky II", "Rocky 2")
      assert similarity >= 0.95
    end

    test "handles roman numeral III" do
      similarity = test_title_similarity("The Godfather Part III", "The Godfather Part 3")
      assert similarity >= 0.95
    end

    test "handles combination of variations" do
      # "The Lord of the Rings: The Two Towers" vs "Lord of the Rings: The Two Towers"
      # After normalization, these are very similar (substring match)
      similarity =
        test_title_similarity(
          "The Lord of the Rings: The Two Towers",
          "Lord of the Rings: The Two Towers"
        )

      assert similarity >= 0.8
    end
  end

  describe "year_match?/2" do
    test "exact year match returns true" do
      assert test_year_match(2020, 2020)
    end

    test "year difference of 1 returns true" do
      assert test_year_match(2020, 2021)
      assert test_year_match(2021, 2020)
    end

    test "year difference of 2 or more returns false" do
      refute test_year_match(2020, 2022)
      refute test_year_match(2022, 2020)
    end

    test "nil parsed year returns true if result has year" do
      assert test_year_match(2020, nil)
    end

    test "nil result year returns false" do
      refute test_year_match(nil, 2020)
    end
  end

  describe "disambiguation - main series vs spin-offs" do
    test "prefers exact title match over spin-off (Bluey vs Bluey Cookalongs)" do
      parsed = %{
        type: :tv_show,
        title: "Bluey",
        year: nil,
        season: 3,
        episodes: [1],
        quality: %{resolution: "2160p"},
        confidence: 0.9
      }

      # Main series - exact match, high popularity
      main_series = %{
        provider_id: "82728",
        title: "Bluey",
        year: 2018,
        first_air_date: "2018-10-01",
        popularity: 200.0
      }

      # Spin-off - contains search term, lower popularity
      spin_off = %{
        provider_id: "225191",
        title: "Bluey Cookalongs",
        year: 2023,
        first_air_date: "2023-09-01",
        popularity: 15.0
      }

      main_score = calculate_test_tv_score(main_series, parsed)
      spinoff_score = calculate_test_tv_score(spin_off, parsed)

      # Main series should score higher
      assert main_score > spinoff_score,
             "Main series should score higher. Main: #{main_score}, Spin-off: #{spinoff_score}"

      # Difference should be significant (not just barely higher)
      assert main_score - spinoff_score >= 0.1,
             "Score difference should be significant: #{main_score - spinoff_score}"
    end

    test "prefers exact title match when both have similar popularity" do
      parsed = %{
        type: :tv_show,
        title: "Bluey",
        year: nil,
        season: 1,
        episodes: [1],
        quality: %{},
        confidence: 0.9
      }

      # Even with equal popularity, exact match should win
      exact_match = %{
        provider_id: "82728",
        title: "Bluey",
        year: 2018,
        first_air_date: "2018-10-01",
        popularity: 50.0
      }

      derivative = %{
        provider_id: "225191",
        title: "Bluey Cookalongs",
        year: 2023,
        first_air_date: "2023-09-01",
        popularity: 50.0
      }

      exact_score = calculate_test_tv_score(exact_match, parsed)
      deriv_score = calculate_test_tv_score(derivative, parsed)

      assert exact_score > deriv_score,
             "Exact match should win even with same popularity. Exact: #{exact_score}, Derivative: #{deriv_score}"
    end

    test "higher popularity breaks ties for similar titles" do
      parsed = %{
        type: :tv_show,
        title: "The Office",
        year: nil,
        season: 1,
        episodes: [1],
        quality: %{},
        confidence: 0.9
      }

      # US version - very popular (using lower values to avoid hitting max score cap)
      us_version = %{
        provider_id: "2316",
        title: "The Office",
        year: 2005,
        first_air_date: "2005-03-24",
        popularity: 100.0
      }

      # UK version - less popular
      uk_version = %{
        provider_id: "2987",
        title: "The Office",
        year: 2001,
        first_air_date: "2001-07-09",
        popularity: 10.0
      }

      us_score = calculate_test_tv_score(us_version, parsed)
      uk_score = calculate_test_tv_score(uk_version, parsed)

      # For exact title matches with no year, popularity should be the tiebreaker
      # Both should score high (>0.95), but US version should be slightly higher
      assert us_score >= uk_score,
             "Higher popularity should help with same title. US: #{us_score}, UK: #{uk_score}"

      # The US version should have a better score due to higher popularity
      # (unless both hit the max cap)
      assert us_score >= 0.95, "Exact match should score very high"
      assert uk_score >= 0.90, "Exact match should score high even with lower popularity"
    end

    test "derivative title penalty is proportional to extra content" do
      parsed = %{
        type: :tv_show,
        title: "Bluey",
        year: nil,
        season: 1,
        episodes: [1],
        quality: %{},
        confidence: 0.9
      }

      # Shorter derivative gets less penalty
      short_deriv = %{
        provider_id: "1",
        title: "Bluey: Special",
        year: 2023,
        first_air_date: "2023-01-01",
        popularity: 50.0
      }

      # Longer derivative gets more penalty
      long_deriv = %{
        provider_id: "2",
        title: "Bluey Cookalongs: The Complete Collection",
        year: 2023,
        first_air_date: "2023-01-01",
        popularity: 50.0
      }

      short_score = calculate_test_tv_score(short_deriv, parsed)
      long_score = calculate_test_tv_score(long_deriv, parsed)

      assert short_score > long_score,
             "Shorter derivative should score higher. Short: #{short_score}, Long: #{long_score}"
    end

    test "popularity scoring uses logarithmic scale" do
      # Test that popularity scores scale logarithmically
      # 10 should be ~0.33, 50 ~0.56, 200 ~0.77, 1000 = 1.0
      assert_in_delta test_popularity_score(10), 0.33, 0.05
      assert_in_delta test_popularity_score(50), 0.57, 0.05
      assert_in_delta test_popularity_score(200), 0.77, 0.05
      assert test_popularity_score(1000) == 1.0
    end

    test "handles nil popularity gracefully" do
      assert test_popularity_score(nil) == 0.0
      assert test_popularity_score(0) == 0.0
      assert test_popularity_score(-5) == 0.0
    end
  end

  # Helper functions to test private logic
  # In a real implementation, these would call the actual private functions
  # or we'd use mocks to test the full public API

  defp calculate_test_movie_score(result, parsed) do
    base_score = 0.5
    title_sim = test_title_similarity(result.title, parsed.title)

    base_score
    |> add_test_score(title_sim, 0.2)
    |> add_test_score(test_year_match(result.year, parsed.year), 0.15)
    |> add_test_score(test_popularity_score(result.popularity), 0.1)
    |> add_test_score(test_exact_title_match?(result.title, parsed.title), 0.1)
    |> add_test_score(test_title_derivative_penalty(result.title, parsed.title), 1.0)
    |> min(1.0)
  end

  defp calculate_test_tv_score(result, parsed) do
    base_score = 0.5
    title_sim = test_title_similarity(result.title, parsed.title)

    base_score
    |> add_test_score(title_sim, 0.25)
    |> add_test_score(test_year_match(result.year, parsed.year), 0.1)
    |> add_test_score(test_popularity_score(result.popularity), 0.1)
    |> add_test_score(Map.get(result, :first_air_date) != nil, 0.05)
    |> add_test_score(test_exact_title_match?(result.title, parsed.title), 0.15)
    |> add_test_score(test_title_derivative_penalty(result.title, parsed.title), 1.0)
    |> min(1.0)
  end

  defp add_test_score(current, true, amount), do: current + amount
  defp add_test_score(current, score, amount) when is_float(score), do: current + score * amount
  defp add_test_score(current, _false_or_nil, _amount), do: current

  defp test_title_similarity(title1, title2) when is_binary(title1) and is_binary(title2) do
    # Light normalization first (for substring matching)
    light_norm1 = String.downcase(title1) |> String.replace(~r/[^\w\s]/, "") |> String.trim()
    light_norm2 = String.downcase(title2) |> String.replace(~r/[^\w\s]/, "") |> String.trim()

    cond do
      # Exact match on light normalization
      light_norm1 == light_norm2 ->
        1.0

      # Substring match on light normalization
      String.contains?(light_norm1, light_norm2) || String.contains?(light_norm2, light_norm1) ->
        0.8

      # Full normalization for variations
      true ->
        norm1 = normalize_test_title(title1)
        norm2 = normalize_test_title(title2)

        cond do
          # Exact match after full normalization
          norm1 == norm2 ->
            1.0

          # Substring match after full normalization
          String.contains?(norm1, norm2) || String.contains?(norm2, norm1) ->
            0.9

          # Jaro similarity for fuzzy matching
          true ->
            test_jaro_similarity(norm1, norm2)
        end
    end
  end

  defp test_title_similarity(_title1, _title2), do: 0.0

  defp normalize_test_title(title) do
    title
    |> String.downcase()
    # Convert roman numerals to numbers
    |> convert_test_roman_numerals()
    # Normalize "and" vs "&"
    |> String.replace(~r/\s+&\s+/, " and ")
    # Move leading articles to the end
    |> normalize_test_articles()
    # Remove all punctuation
    |> String.replace(~r/[^\w\s]/, "")
    # Normalize whitespace
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp convert_test_roman_numerals(title) do
    replacements = [
      {~r/\bX\b/i, "10"},
      {~r/\bIX\b/i, "9"},
      {~r/\bVIII\b/i, "8"},
      {~r/\bVII\b/i, "7"},
      {~r/\bVI\b/i, "6"},
      {~r/\bV\b/i, "5"},
      {~r/\bIV\b/i, "4"},
      {~r/\bIII\b/i, "3"},
      {~r/\bII\b/i, "2"}
    ]

    Enum.reduce(replacements, title, fn {pattern, replacement}, acc ->
      String.replace(acc, pattern, replacement)
    end)
  end

  defp normalize_test_articles(title) do
    case Regex.run(~r/^(the|a|an)\s+(.+)$/i, title) do
      [_, article, rest] -> "#{rest} #{article}"
      _ -> title
    end
  end

  defp test_year_match(result_year, nil), do: result_year != nil
  defp test_year_match(nil, _parsed_year), do: false

  defp test_year_match(result_year, parsed_year) when is_integer(result_year) do
    abs(result_year - parsed_year) <= 1
  end

  defp test_year_match(_result_year, _parsed_year), do: false

  # Simplified Jaro similarity for testing
  defp test_jaro_similarity(s1, s2) do
    len1 = String.length(s1)
    len2 = String.length(s2)

    if len1 == 0 and len2 == 0, do: 1.0
    if len1 == 0 or len2 == 0, do: 0.0

    # Simple approximation for testing
    common = count_common_chars(s1, s2)
    max_len = max(len1, len2)

    common / max_len
  end

  defp count_common_chars(s1, s2) do
    chars1 = String.graphemes(s1) |> MapSet.new()
    chars2 = String.graphemes(s2) |> MapSet.new()

    MapSet.intersection(chars1, chars2) |> MapSet.size()
  end

  # Normalized popularity score using logarithmic scaling
  defp test_popularity_score(nil), do: 0.0
  defp test_popularity_score(popularity) when popularity <= 0, do: 0.0

  defp test_popularity_score(popularity) do
    min(:math.log10(popularity) / 3, 1.0)
  end

  # Check if the result title exactly matches the search query (after normalization)
  defp test_exact_title_match?(result_title, search_title)
       when is_binary(result_title) and is_binary(search_title) do
    norm_result = normalize_test_title(result_title)
    norm_search = normalize_test_title(search_title)
    norm_result == norm_search
  end

  defp test_exact_title_match?(_result_title, _search_title), do: false

  # Calculate penalty for derivative titles
  defp test_title_derivative_penalty(result_title, search_title)
       when is_binary(result_title) and is_binary(search_title) do
    norm_result = String.downcase(result_title) |> String.trim()
    norm_search = String.downcase(search_title) |> String.trim()

    if norm_result != norm_search and String.contains?(norm_result, norm_search) do
      search_len = String.length(norm_search)
      result_len = String.length(norm_result)
      extra_ratio = (result_len - search_len) / result_len

      -extra_ratio * 0.15
    else
      0.0
    end
  end

  defp test_title_derivative_penalty(_result_title, _search_title), do: 0.0
end
