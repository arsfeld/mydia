defmodule Mydia.Settings.QualityMatcher do
  @moduledoc """
  Matches and scores search results against quality profiles.

  This module provides functionality to:
  - Check if a SearchResult meets a quality profile's requirements
  - Calculate quality scores for ranking multiple matches
  - Determine if a result would be an upgrade for existing media
  """

  alias Mydia.Indexers.SearchResult
  alias Mydia.Settings.QualityProfile

  @doc """
  Checks if a search result matches a quality profile's requirements.

  Returns `{:ok, score}` if the result matches, where score is 0-100.
  Returns `{:error, reason}` if the result doesn't match.

  ## Examples

      iex> result = %SearchResult{...}
      iex> profile = %QualityProfile{...}
      iex> QualityMatcher.matches?(result, profile)
      {:ok, 85}

      iex> QualityMatcher.matches?(bad_result, profile)
      {:error, :quality_not_allowed}
  """
  @spec matches?(SearchResult.t(), QualityProfile.t()) ::
          {:ok, non_neg_integer()} | {:error, atom()}
  def matches?(%SearchResult{} = result, %QualityProfile{} = profile) do
    with :ok <- check_quality_allowed(result, profile),
         :ok <- check_size_constraints(result, profile),
         :ok <- check_source_allowed(result, profile) do
      score = calculate_score(result, profile)
      {:ok, score}
    end
  end

  @doc """
  Calculates a quality score for a search result against a profile.

  Returns a score from 0-100, where higher is better.

  The score considers:
  - Quality match (40 points) - exact match to preferred quality
  - Source match (30 points) - match to preferred sources
  - Size optimization (20 points) - closer to middle of size range
  - Seeder health (10 points) - more seeders = better

  ## Examples

      iex> result = %SearchResult{...}
      iex> profile = %QualityProfile{...}
      iex> QualityMatcher.calculate_score(result, profile)
      85
  """
  @spec calculate_score(SearchResult.t(), QualityProfile.t()) :: non_neg_integer()
  def calculate_score(%SearchResult{} = result, %QualityProfile{} = profile) do
    quality_score = score_quality_match(result, profile)
    source_score = score_source_match(result, profile)
    size_score = score_size_optimization(result, profile)
    health_score = score_seeder_health(result)

    # Weighted total (max 100)
    round(quality_score * 0.4 + source_score * 0.3 + size_score * 0.2 + health_score * 0.1)
  end

  @doc """
  Checks if a result would be an upgrade over a current quality.

  Returns `true` if the result's quality is better than the current quality
  and upgrades are allowed by the profile.

  ## Examples

      iex> QualityMatcher.is_upgrade?(result, profile, "720p")
      true

      iex> QualityMatcher.is_upgrade?(result, profile, "2160p")
      false  # Already at max quality
  """
  @spec is_upgrade?(SearchResult.t(), QualityProfile.t(), String.t() | nil) :: boolean()
  def is_upgrade?(_result, %QualityProfile{upgrades_allowed: false}, _current_quality) do
    false
  end

  def is_upgrade?(%SearchResult{quality: nil}, _profile, _current_quality) do
    false
  end

  def is_upgrade?(%SearchResult{} = result, %QualityProfile{} = profile, current_quality) do
    result_quality = result.quality.resolution

    cond do
      # No current quality means this would be the first
      is_nil(current_quality) ->
        true

      # Check if result quality is in allowed list
      result_quality not in profile.qualities ->
        false

      # If there's an upgrade_until_quality, don't exceed it
      profile.upgrade_until_quality && current_quality == profile.upgrade_until_quality ->
        false

      # Compare quality levels
      true ->
        quality_level(result_quality) > quality_level(current_quality)
    end
  end

  ## Private Functions

  defp check_quality_allowed(%SearchResult{quality: nil}, _profile) do
    {:error, :quality_unknown}
  end

  defp check_quality_allowed(%SearchResult{quality: quality}, %QualityProfile{} = profile) do
    if quality.resolution in profile.qualities do
      :ok
    else
      {:error, :quality_not_allowed}
    end
  end

  defp check_size_constraints(%SearchResult{size: size}, %QualityProfile{} = profile) do
    rules = profile.rules || %{}
    min_size_bytes = (rules["min_size_mb"] || 0) * 1024 * 1024
    max_size_bytes = (rules["max_size_mb"] || 0) * 1024 * 1024

    cond do
      # No constraints
      min_size_bytes == 0 && max_size_bytes == 0 ->
        :ok

      # Only min constraint
      min_size_bytes > 0 && max_size_bytes == 0 && size < min_size_bytes ->
        {:error, :too_small}

      # Only max constraint
      max_size_bytes > 0 && min_size_bytes == 0 && size > max_size_bytes ->
        {:error, :too_large}

      # Both constraints
      min_size_bytes > 0 && max_size_bytes > 0 ->
        if size < min_size_bytes do
          {:error, :too_small}
        else
          if size > max_size_bytes do
            {:error, :too_large}
          else
            :ok
          end
        end

      # Default allow
      true ->
        :ok
    end
  end

  defp check_source_allowed(_result, _profile) do
    # For now, we don't block based on source
    # In the future, we could add blocked_sources to profile rules
    :ok
  end

  # Score quality match (0-100)
  defp score_quality_match(%SearchResult{quality: nil}, _profile), do: 0

  defp score_quality_match(%SearchResult{quality: quality}, %QualityProfile{} = profile) do
    rules = profile.rules || %{}
    preferred_quality = profile.upgrade_until_quality || List.last(profile.qualities)

    cond do
      # Exact match to preferred quality
      quality.resolution == preferred_quality ->
        100

      # Match one of the allowed qualities
      quality.resolution in profile.qualities ->
        # Score based on quality level relative to preferred
        result_level = quality_level(quality.resolution)
        preferred_level = quality_level(preferred_quality)

        if result_level <= preferred_level do
          # Scale from 50-99 based on how close to preferred
          50 + round(result_level / preferred_level * 49)
        else
          # Higher than preferred, give moderate score
          50
        end

      # Not in allowed list
      true ->
        0
    end
  end

  # Score source match (0-100)
  defp score_source_match(%SearchResult{quality: nil}, _profile), do: 50

  defp score_source_match(%SearchResult{quality: quality}, %QualityProfile{} = profile) do
    rules = profile.rules || %{}
    preferred_sources = rules["preferred_sources"] || []

    if Enum.empty?(preferred_sources) do
      # No preference, give neutral score
      50
    else
      source = quality.source || ""

      # Check if result's source is in preferred list
      if Enum.any?(preferred_sources, &String.contains?(source, &1)) do
        100
      else
        25
      end
    end
  end

  # Score size optimization (0-100)
  defp score_size_optimization(%SearchResult{size: size}, %QualityProfile{} = profile) do
    rules = profile.rules || %{}
    min_size_bytes = (rules["min_size_mb"] || 0) * 1024 * 1024
    max_size_bytes = (rules["max_size_mb"] || 0) * 1024 * 1024

    if min_size_bytes == 0 && max_size_bytes == 0 do
      # No size preference, give neutral score
      50
    else
      # Calculate how close to the middle of the range
      # Closer to middle = higher score
      mid_size = (min_size_bytes + max_size_bytes) / 2
      range = max_size_bytes - min_size_bytes

      if range > 0 do
        distance_from_mid = abs(size - mid_size)
        score = 100 - round(distance_from_mid / range * 100)
        max(0, score)
      else
        50
      end
    end
  end

  # Score seeder health (0-100)
  defp score_seeder_health(%SearchResult{seeders: seeders}) do
    # Logarithmic scale - more seeders = better, with diminishing returns
    cond do
      seeders == 0 -> 0
      seeders < 5 -> 30
      seeders < 20 -> 60
      seeders < 50 -> 80
      true -> 100
    end
  end

  # Map quality strings to numeric levels for comparison
  defp quality_level("360p"), do: 1
  defp quality_level("480p"), do: 2
  defp quality_level("576p"), do: 3
  defp quality_level("720p"), do: 4
  defp quality_level("1080p"), do: 5
  defp quality_level("2160p"), do: 6
  defp quality_level(_), do: 0
end
