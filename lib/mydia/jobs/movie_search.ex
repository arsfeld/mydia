defmodule Mydia.Jobs.MovieSearch do
  @moduledoc """
  Background job for searching and downloading movie releases.

  This job searches indexers for movie releases and initiates downloads
  for the best matches. Supports both background execution for all monitored
  movies and UI-triggered searches for specific movies.

  ## Execution Modes

  - `"all_monitored"` - Search all monitored movies without files (scheduled)
  - `"specific"` - Search a single movie by ID (UI-triggered)

  ## Examples

      # Queue a search for all monitored movies
      %{mode: "all_monitored"}
      |> MovieSearch.new()
      |> Oban.insert()

      # Queue a search for a specific movie
      %{mode: "specific", media_item_id: 123}
      |> MovieSearch.new()
      |> Oban.insert()
  """

  use Oban.Worker,
    queue: :search,
    max_attempts: 3,
    unique: [period: 60, fields: [:args]]

  require Logger

  import Ecto.Query, warn: false

  alias Mydia.{Repo, Media, Indexers, Downloads}
  alias Mydia.Indexers.ReleaseRanker
  alias Mydia.Media.MediaItem
  alias Phoenix.PubSub

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"mode" => "all_monitored"} = args}) do
    start_time = System.monotonic_time(:millisecond)
    Logger.info("Starting automatic search for all monitored movies")

    movies = load_monitored_movies_without_files()
    total_count = length(movies)

    Logger.info("Found #{total_count} monitored movies without files")

    if total_count == 0 do
      duration = System.monotonic_time(:millisecond) - start_time

      Logger.info("No movies to search", duration_ms: duration)

      :ok
    else
      results = Enum.map(movies, &search_movie(&1, args))

      successful = Enum.count(results, &(&1 == :ok))
      failed = Enum.count(results, &match?({:error, _}, &1))
      no_results = Enum.count(results, &(&1 == :no_results))
      duration = System.monotonic_time(:millisecond) - start_time

      Logger.info("Automatic movie search completed",
        duration_ms: duration,
        total: total_count,
        successful: successful,
        failed: failed,
        no_results: no_results
      )

      :ok
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"mode" => "specific", "media_item_id" => media_item_id} = args}) do
    start_time = System.monotonic_time(:millisecond)
    Logger.info("Starting search for specific movie", media_item_id: media_item_id)

    result =
      try do
        media_item = Media.get_media_item!(media_item_id)

        case media_item do
          %MediaItem{type: "movie"} = movie ->
            search_movie_with_stats(movie, args)

          %MediaItem{type: type} ->
            Logger.error("Invalid media type for movie search",
              media_item_id: media_item_id,
              type: type
            )

            {:error, :invalid_type}
        end
      rescue
        Ecto.NoResultsError ->
          Logger.error("Media item not found", media_item_id: media_item_id)
          {:error, :not_found}
      end

    duration = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, stats} ->
        Logger.info("Movie search completed",
          duration_ms: duration,
          media_item_id: media_item_id,
          stats: stats
        )

        # Broadcast search completion for UI feedback
        broadcast_search_completed(media_item_id, stats)

        :ok

      {:no_results, stats} ->
        Logger.info("Movie search completed with no results",
          duration_ms: duration,
          media_item_id: media_item_id,
          stats: stats
        )

        # Broadcast search completion for UI feedback
        broadcast_search_completed(media_item_id, stats)

        :ok

      {:error, reason} ->
        Logger.error("Movie search failed",
          error: inspect(reason),
          duration_ms: duration,
          media_item_id: media_item_id
        )

        # Broadcast failure for UI feedback
        broadcast_search_completed(media_item_id, %{
          indexers_searched: 0,
          results_found: 0,
          downloads_initiated: 0,
          error: inspect(reason)
        })

        {:error, reason}
    end
  end

  ## Private Functions

  defp broadcast_search_completed(media_item_id, stats) do
    PubSub.broadcast(
      Mydia.PubSub,
      "downloads",
      {:search_completed, media_item_id, stats}
    )
  end

  defp search_movie_with_stats(%MediaItem{} = movie, args) do
    query = build_search_query(movie)
    indexers_count = count_enabled_indexers()

    Logger.info("Searching for movie",
      media_item_id: movie.id,
      title: movie.title,
      year: movie.year,
      query: query,
      indexers_count: indexers_count
    )

    case Indexers.search_all(query, min_seeders: 5) do
      {:ok, []} ->
        Logger.warning("No results found for movie",
          media_item_id: movie.id,
          title: movie.title,
          query: query
        )

        {:no_results,
         %{
           indexers_searched: indexers_count,
           results_found: 0,
           downloads_initiated: 0
         }}

      {:ok, results} ->
        Logger.info("Found #{length(results)} results for movie",
          media_item_id: movie.id,
          title: movie.title
        )

        {status, downloads_initiated} = process_search_results_with_count(movie, results, args)

        stats = %{
          indexers_searched: indexers_count,
          results_found: length(results),
          downloads_initiated: downloads_initiated
        }

        case status do
          :ok -> {:ok, stats}
          :no_results -> {:no_results, stats}
        end
    end
  end

  defp process_search_results_with_count(movie, results, args) do
    ranking_opts = build_ranking_options(movie, args)

    case ReleaseRanker.select_best_result(results, ranking_opts) do
      nil ->
        Logger.warning("No suitable results after ranking for movie",
          media_item_id: movie.id,
          title: movie.title,
          total_results: length(results)
        )

        {:no_results, 0}

      %{result: best_result, score: score, breakdown: breakdown} ->
        Logger.info("Selected best result for movie",
          media_item_id: movie.id,
          title: movie.title,
          result_title: best_result.title,
          score: score,
          breakdown: breakdown
        )

        case initiate_download(movie, best_result) do
          :ok -> {:ok, 1}
          {:error, _} -> {:no_results, 0}
        end
    end
  end

  defp count_enabled_indexers do
    # Count enabled indexers from Settings
    indexers = Mydia.Settings.list_indexer_configs()
    enabled_count = Enum.count(indexers, & &1.enabled)

    # Also count Cardigann indexers if feature is enabled
    cardigann_count =
      if Application.get_env(:mydia, :features, [])[:cardigann_indexers] do
        Mydia.Indexers.list_cardigann_definitions()
        |> Enum.count(& &1.enabled)
      else
        0
      end

    enabled_count + cardigann_count
  end

  defp load_monitored_movies_without_files do
    MediaItem
    |> where([m], m.type == "movie")
    |> where([m], m.monitored == true)
    |> join(:left, [m], mf in assoc(m, :media_files))
    |> group_by([m], m.id)
    |> having([m, mf], count(mf.id) == 0)
    |> Repo.all()
  end

  defp search_movie(%MediaItem{} = movie, args) do
    query = build_search_query(movie)

    Logger.info("Searching for movie",
      media_item_id: movie.id,
      title: movie.title,
      year: movie.year,
      query: query
    )

    case Indexers.search_all(query, min_seeders: 5) do
      {:ok, []} ->
        Logger.warning("No results found for movie",
          media_item_id: movie.id,
          title: movie.title,
          query: query
        )

        :no_results

      {:ok, results} ->
        Logger.info("Found #{length(results)} results for movie",
          media_item_id: movie.id,
          title: movie.title
        )

        process_search_results(movie, results, args)
    end
  end

  defp build_search_query(%MediaItem{title: title, year: nil}) do
    title
  end

  defp build_search_query(%MediaItem{title: title, year: year}) do
    "#{title} #{year}"
  end

  defp process_search_results(movie, results, args) do
    ranking_opts = build_ranking_options(movie, args)

    case ReleaseRanker.select_best_result(results, ranking_opts) do
      nil ->
        Logger.warning("No suitable results after ranking for movie",
          media_item_id: movie.id,
          title: movie.title,
          total_results: length(results)
        )

        :no_results

      %{result: best_result, score: score, breakdown: breakdown} ->
        Logger.info("Selected best result for movie",
          media_item_id: movie.id,
          title: movie.title,
          result_title: best_result.title,
          score: score,
          breakdown: breakdown
        )

        initiate_download(movie, best_result)
    end
  end

  defp build_ranking_options(movie, args) do
    # Start with base options
    # Include search_query for title relevance scoring
    base_opts = [
      min_seeders: Map.get(args, "min_seeders", 5),
      size_range: Map.get(args, "size_range", {500, 20_000}),
      search_query: build_search_query(movie)
    ]

    # Add quality profile preferences if available
    opts_with_quality =
      case load_quality_profile(movie) do
        nil ->
          base_opts

        quality_profile ->
          Keyword.merge(base_opts, build_quality_options(quality_profile))
      end

    # Add any custom blocked/preferred tags from args
    opts_with_quality
    |> maybe_add_option(:blocked_tags, Map.get(args, "blocked_tags"))
    |> maybe_add_option(:preferred_tags, Map.get(args, "preferred_tags"))
  end

  defp load_quality_profile(%MediaItem{quality_profile_id: nil}), do: nil

  defp load_quality_profile(%MediaItem{} = movie) do
    movie
    |> Repo.preload(:quality_profile)
    |> Map.get(:quality_profile)
  end

  defp build_quality_options(quality_profile) do
    # Extract preferred qualities from quality profile
    # The :qualities field contains the list of allowed resolutions in preference order
    quality_opts =
      case Map.get(quality_profile, :qualities) do
        nil -> []
        qualities when is_list(qualities) -> [preferred_qualities: qualities]
        _ -> []
      end

    # Extract min_ratio from rules if present
    rules_opts =
      case Map.get(quality_profile, :rules) do
        %{"min_ratio" => min_ratio} when is_number(min_ratio) ->
          [min_ratio: min_ratio]

        _ ->
          []
      end

    Keyword.merge(quality_opts, rules_opts)
  end

  defp maybe_add_option(opts, _key, nil), do: opts
  defp maybe_add_option(opts, _key, []), do: opts
  defp maybe_add_option(opts, key, value), do: Keyword.put(opts, key, value)

  defp initiate_download(movie, result) do
    case Downloads.initiate_download(result, media_item_id: movie.id) do
      {:ok, download} ->
        Logger.info("Successfully initiated download for movie",
          media_item_id: movie.id,
          title: movie.title,
          download_id: download.id,
          result_title: result.title
        )

        :ok

      {:error, reason} ->
        Logger.error("Failed to initiate download for movie",
          media_item_id: movie.id,
          title: movie.title,
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end
end
