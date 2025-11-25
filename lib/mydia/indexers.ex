defmodule Mydia.Indexers do
  @moduledoc """
  The Indexers context handles indexer and search provider operations.

  This module provides the main API for searching across configured indexers,
  managing indexer configurations, and registering indexer adapters.

  ## Adapter Registration

  Indexer adapters must be registered before they can be used. Registration
  happens automatically at application startup via `register_adapters/0`.

  ## Searching

  To search across all configured indexers:

      Mydia.Indexers.search_all("Ubuntu 22.04", min_seeders: 5)

  To search a specific indexer:

      config = Mydia.Settings.get_indexer_config!(id)
      Mydia.Indexers.search(config, "Ubuntu 22.04")
  """

  require Logger
  alias Mydia.Indexers.Adapter
  alias Mydia.Indexers.SearchResult
  alias Mydia.Indexers.RateLimiter
  alias Mydia.Indexers.ReleaseRanker
  alias Mydia.Indexers.CardigannDefinition
  alias Mydia.Settings
  alias Mydia.Repo
  import Ecto.Query

  @doc """
  Registers all known indexer adapters with the registry.

  This function is called automatically during application startup.
  Adapters must be registered before they can be used.

  ## Registered Adapters

  Currently supported adapters:
    - `:prowlarr` - Prowlarr indexer aggregator
    - `:jackett` - Jackett indexer proxy
    - `:cardigann` - Native Cardigann definition support
  """
  def register_adapters do
    Logger.info("Registering indexer adapters...")

    # Register adapters
    Adapter.Registry.register(:prowlarr, Mydia.Indexers.Adapter.Prowlarr)
    Adapter.Registry.register(:jackett, Mydia.Indexers.Adapter.Jackett)
    Adapter.Registry.register(:cardigann, Mydia.Indexers.Adapter.Cardigann)

    Logger.info("Indexer adapter registration complete")
    :ok
  end

  @doc """
  Searches a specific indexer with the given query.

  ## Parameters
    - `config` - Indexer configuration map or IndexerConfig struct
    - `query` - Search query string
    - `opts` - Search options (see `Mydia.Indexers.Adapter` for available options)

  ## Examples

      iex> config = %{type: :prowlarr, base_url: "http://localhost:9696", api_key: "..."}
      iex> Mydia.Indexers.search(config, "Ubuntu")
      {:ok, [%SearchResult{}, ...]}
  """
  def search(config, query, opts \\ [])

  def search(%Settings.IndexerConfig{} = config, query, opts) do
    # Check rate limit before making the request
    case RateLimiter.check_rate_limit(config.id, config.rate_limit) do
      :ok ->
        adapter_config = indexer_config_to_adapter_config(config)

        result = search(adapter_config, query, opts)

        # Record the request if successful (even if search returned no results)
        case result do
          {:ok, _results} -> RateLimiter.record_request(config.id)
          {:error, _} -> :ok
        end

        result

      {:error, :rate_limited, retry_after} ->
        Logger.warning(
          "Rate limit exceeded for indexer #{config.name}, retry after #{retry_after}ms"
        )

        {:error, Adapter.Error.rate_limited("Rate limit exceeded, retry after #{retry_after}ms")}
    end
  end

  def search(%{type: type} = config, query, opts) when is_atom(type) do
    with {:ok, adapter} <- Adapter.Registry.get_adapter(type) do
      adapter.search(config, query, opts)
    end
  end

  @doc """
  Searches all enabled indexers configured in the system.

  Results from all indexers are returned in a single list, deduplicated,
  and ranked by quality score and seeders.

  This function executes searches concurrently using Task.async_stream with
  configurable timeouts per indexer. Performance metrics are logged for each
  indexer, and individual failures don't block other results.

  ## Parameters
    - `query` - Search query string
    - `opts` - Search options:
      - `:min_seeders` - Minimum seeder count filter (default: 0)
      - `:max_results` - Maximum number of results to return (default: 100)
      - `:deduplicate` - Whether to deduplicate results (default: true)

  ## Examples

      iex> Mydia.Indexers.search_all("Ubuntu 22.04")
      {:ok, [%SearchResult{indexer: "Prowlarr", ...}, ...]}

      iex> Mydia.Indexers.search_all("Ubuntu", min_seeders: 10, max_results: 50)
      {:ok, [%SearchResult{}, ...]}
  """
  def search_all(query, opts \\ []) do
    min_seeders = Keyword.get(opts, :min_seeders, 0)
    max_results = Keyword.get(opts, :max_results, 100)
    should_deduplicate = Keyword.get(opts, :deduplicate, true)

    # Get traditional indexers (Prowlarr, Jackett)
    indexers = Settings.list_indexer_configs()
    enabled_indexers = Enum.filter(indexers, & &1.enabled)

    # Get enabled Cardigann definitions if feature is enabled
    cardigann_configs = get_enabled_cardigann_configs()

    all_indexers = enabled_indexers ++ cardigann_configs

    if all_indexers == [] do
      Logger.info("No enabled indexers found for query: #{query}")
      {:ok, []}
    else
      start_time = System.monotonic_time(:millisecond)

      results =
        all_indexers
        |> Task.async_stream(
          fn config -> search_with_metrics(config, query, opts) end,
          timeout: :infinity,
          max_concurrency: System.schedulers_online() * 2,
          on_timeout: :kill_task
        )
        |> Enum.flat_map(fn
          {:ok, {_metrics, results}} ->
            results

          {:exit, reason} ->
            Logger.error("Indexer search task crashed: #{inspect(reason)}")
            []
        end)
        |> filter_by_seeders(min_seeders)
        |> then(fn results ->
          if should_deduplicate, do: deduplicate_results(results), else: results
        end)
        |> rank_results(min_seeders)
        |> Enum.take(max_results)

      total_time = System.monotonic_time(:millisecond) - start_time

      Logger.info(
        "Search completed: query=#{query}, indexers=#{length(all_indexers)}, " <>
          "cardigann=#{length(cardigann_configs)}, results=#{length(results)}, time=#{total_time}ms"
      )

      {:ok, results}
    end
  end

  @doc """
  Tests the connection to an indexer.

  ## Examples

      iex> config = %{type: :prowlarr, base_url: "http://localhost:9696", api_key: "..."}
      iex> Mydia.Indexers.test_connection(config)
      {:ok, %{name: "Prowlarr", version: "1.0.0"}}
  """
  def test_connection(%Settings.IndexerConfig{} = config) do
    adapter_config = indexer_config_to_adapter_config(config)
    test_connection(adapter_config)
  end

  def test_connection(%{type: type} = config) when is_atom(type) do
    with {:ok, adapter} <- Adapter.Registry.get_adapter(type) do
      adapter.test_connection(config)
    end
  end

  @doc """
  Gets the capabilities of an indexer.

  ## Examples

      iex> config = %{type: :prowlarr, base_url: "http://localhost:9696", api_key: "..."}
      iex> Mydia.Indexers.get_capabilities(config)
      {:ok, %{searching: %{...}, categories: [...]}}
  """
  def get_capabilities(%Settings.IndexerConfig{} = config) do
    adapter_config = indexer_config_to_adapter_config(config)
    get_capabilities(adapter_config)
  end

  def get_capabilities(%{type: type} = config) when is_atom(type) do
    with {:ok, adapter} <- Adapter.Registry.get_adapter(type) do
      adapter.get_capabilities(config)
    end
  end

  ## Private Functions

  # Fetches enabled Cardigann definitions and converts them to adapter config format
  defp get_enabled_cardigann_configs do
    alias Mydia.Indexers.CardigannFeatureFlags

    if CardigannFeatureFlags.enabled?() do
      list_cardigann_definitions(enabled: true)
      |> Enum.map(&cardigann_definition_to_config/1)
    else
      []
    end
  end

  # Converts a CardigannDefinition to the config map expected by the Cardigann adapter
  defp cardigann_definition_to_config(%CardigannDefinition{} = definition) do
    %{
      type: :cardigann,
      name: definition.name,
      indexer_id: definition.indexer_id,
      enabled: definition.enabled,
      user_settings: definition.config || %{}
    }
  end

  defp search_with_metrics(config, query, opts) do
    start_time = System.monotonic_time(:millisecond)

    result =
      case search(config, query, opts) do
        {:ok, results} ->
          {true, results}

        {:error, error} ->
          Logger.warning("Indexer search failed for #{config.name}: #{inspect(error)}")

          {false, []}
      end

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    {success, results} = result

    metrics = %{
      indexer: config.name,
      success: success,
      duration_ms: duration,
      result_count: length(results)
    }

    Logger.debug(
      "Indexer search: name=#{config.name}, success=#{success}, " <>
        "results=#{length(results)}, duration=#{duration}ms"
    )

    {metrics, results}
  end

  defp filter_by_seeders(results, min_seeders) when min_seeders > 0 do
    Enum.filter(results, fn result -> result.seeders >= min_seeders end)
  end

  defp filter_by_seeders(results, _min_seeders), do: results

  defp deduplicate_results(results) do
    # Group results by normalized title and hash
    results
    |> Enum.group_by(&dedup_key/1)
    |> Enum.map(fn {_key, group} ->
      # For each group, merge duplicates by taking the best one
      merge_duplicates(group)
    end)
  end

  defp dedup_key(result) do
    # Extract hash from magnet link if available
    hash = extract_hash_from_url(result.download_url)
    normalized_title = normalize_title(result.title)

    {hash, normalized_title}
  end

  defp extract_hash_from_url(url) when is_binary(url) do
    case Regex.run(~r/urn:btih:([a-f0-9]{40})/i, url) do
      [_, hash] -> String.downcase(hash)
      nil -> nil
    end
  end

  defp normalize_title(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "")
  end

  defp merge_duplicates([single]), do: single

  defp merge_duplicates(duplicates) do
    # When we have duplicates, prefer:
    # 1. Results with more seeders
    # 2. Results from more reliable sources (if we had source ranking)
    # 3. Results with complete metadata
    Enum.max_by(duplicates, fn result ->
      {result.seeders, has_complete_metadata?(result)}
    end)
  end

  defp has_complete_metadata?(%SearchResult{quality: quality}) do
    quality != nil && quality.resolution != nil && quality.source != nil
  end

  defp rank_results(results, min_seeders) do
    # Use the unified ReleaseRanker for consistent scoring across manual and automated searches
    # This provides sophisticated ranking with size scoring, age scoring, and seeder ratio multipliers
    ranked_results = ReleaseRanker.rank_all(results, min_seeders: min_seeders)

    # Extract the SearchResult from each RankedResult to maintain the expected return type
    Enum.map(ranked_results, fn ranked -> ranked.result end)
  end

  defp indexer_config_to_adapter_config(%Settings.IndexerConfig{} = config) do
    # Parse base_url to extract host, port, and use_ssl
    uri = URI.parse(config.base_url)

    # Get timeout from connection_settings or use default
    timeout =
      case config.connection_settings do
        %{"timeout" => timeout} when is_integer(timeout) -> timeout
        _ -> 30_000
      end

    %{
      type: config.type,
      name: config.name,
      host: uri.host || "localhost",
      port: uri.port || default_port(uri.scheme),
      api_key: config.api_key,
      use_ssl: uri.scheme == "https",
      options: %{
        indexer_ids: config.indexer_ids || [],
        categories: config.categories || [],
        rate_limit: config.rate_limit,
        timeout: timeout,
        base_path: uri.path
      }
    }
  end

  defp default_port("https"), do: 443
  defp default_port("http"), do: 80
  defp default_port(_), do: 80

  ## Cardigann Definition Management

  @doc """
  Lists all Cardigann definitions with optional filtering.

  ## Options
    - `:type` - Filter by indexer type ("public", "private", "semi-private")
    - `:language` - Filter by language code (e.g., "en-US")
    - `:enabled` - Filter by enabled status (true/false)
    - `:search` - Search by name or description (case-insensitive)

  ## Examples

      iex> Mydia.Indexers.list_cardigann_definitions()
      [%CardigannDefinition{}, ...]

      iex> Mydia.Indexers.list_cardigann_definitions(type: "public", enabled: true)
      [%CardigannDefinition{}, ...]
  """
  def list_cardigann_definitions(opts \\ []) do
    query = from(d in CardigannDefinition, order_by: [asc: d.name])

    query
    |> apply_cardigann_filters(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single Cardigann definition by ID.

  Raises `Ecto.NoResultsError` if the definition does not exist.
  """
  def get_cardigann_definition!(id) do
    Repo.get!(CardigannDefinition, id)
  end

  @doc """
  Gets a single Cardigann definition by indexer_id.

  Returns nil if the definition does not exist.
  """
  def get_cardigann_definition_by_indexer_id(indexer_id) do
    Repo.get_by(CardigannDefinition, indexer_id: indexer_id)
  end

  @doc """
  Enables a Cardigann indexer definition.

  ## Examples

      iex> enable_cardigann_definition(definition)
      {:ok, %CardigannDefinition{enabled: true}}
  """
  def enable_cardigann_definition(%CardigannDefinition{} = definition) do
    definition
    |> CardigannDefinition.toggle_changeset(%{enabled: true})
    |> Repo.update()
  end

  @doc """
  Disables a Cardigann indexer definition.

  ## Examples

      iex> disable_cardigann_definition(definition)
      {:ok, %CardigannDefinition{enabled: false}}
  """
  def disable_cardigann_definition(%CardigannDefinition{} = definition) do
    definition
    |> CardigannDefinition.toggle_changeset(%{enabled: false})
    |> Repo.update()
  end

  @doc """
  Updates the configuration for a Cardigann definition (credentials, etc.).

  ## Examples

      iex> configure_cardigann_definition(definition, %{username: "user", password: "pass"})
      {:ok, %CardigannDefinition{config: %{username: "user", ...}}}
  """
  def configure_cardigann_definition(%CardigannDefinition{} = definition, config) do
    definition
    |> CardigannDefinition.config_changeset(%{config: config})
    |> Repo.update()
  end

  @doc """
  Tests the connection to a Cardigann indexer definition.

  This validates that the indexer is reachable and properly configured.

  ## Examples

      iex> test_cardigann_definition(definition)
      {:ok, %{success: true, status: "healthy", ...}}
  """
  def test_cardigann_definition(%CardigannDefinition{} = definition) do
    alias Mydia.Indexers.CardigannHealthCheck

    CardigannHealthCheck.execute_health_check(definition)
  end

  @doc """
  Tests connection to a Cardigann indexer by ID.

  Performs a test search to verify connectivity, authentication, and response.
  Updates the health status in the database.

  ## Examples

      iex> test_cardigann_connection("abc-123")
      {:ok, %{success: true, status: "healthy", ...}}
  """
  def test_cardigann_connection(definition_id) when is_binary(definition_id) do
    alias Mydia.Indexers.CardigannHealthCheck

    CardigannHealthCheck.test_connection(definition_id)
  end

  @doc """
  Counts Cardigann definitions by status.

  Returns a map with counts for enabled, disabled, and total definitions.

  ## Examples

      iex> count_cardigann_definitions()
      %{total: 100, enabled: 25, disabled: 75}
  """
  def count_cardigann_definitions do
    total = Repo.aggregate(CardigannDefinition, :count, :id)
    enabled = Repo.aggregate(from(d in CardigannDefinition, where: d.enabled), :count, :id)

    %{
      total: total,
      enabled: enabled,
      disabled: total - enabled
    }
  end

  ## FlareSolverr Functions

  @doc """
  Updates the FlareSolverr settings for a Cardigann definition.

  ## Examples

      iex> update_flaresolverr_settings(definition, %{flaresolverr_enabled: true})
      {:ok, %CardigannDefinition{flaresolverr_enabled: true}}
  """
  def update_flaresolverr_settings(%CardigannDefinition{} = definition, attrs) do
    definition
    |> CardigannDefinition.flaresolverr_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Sets whether a Cardigann definition requires FlareSolverr.

  This is typically set automatically when Cloudflare challenges are detected.

  ## Examples

      iex> set_flaresolverr_required(definition, true)
      {:ok, %CardigannDefinition{flaresolverr_required: true}}
  """
  def set_flaresolverr_required(%CardigannDefinition{} = definition, required?)
      when is_boolean(required?) do
    update_flaresolverr_settings(definition, %{flaresolverr_required: required?})
  end

  @doc """
  Lists all Cardigann definitions that have FlareSolverr enabled.

  ## Examples

      iex> list_flaresolverr_enabled_definitions()
      [%CardigannDefinition{flaresolverr_enabled: true}, ...]
  """
  def list_flaresolverr_enabled_definitions do
    from(d in CardigannDefinition,
      where: d.flaresolverr_enabled == true,
      order_by: [asc: d.name]
    )
    |> Repo.all()
  end

  @doc """
  Lists all Cardigann definitions that require FlareSolverr.

  ## Examples

      iex> list_flaresolverr_required_definitions()
      [%CardigannDefinition{flaresolverr_required: true}, ...]
  """
  def list_flaresolverr_required_definitions do
    from(d in CardigannDefinition,
      where: d.flaresolverr_required == true,
      order_by: [asc: d.name]
    )
    |> Repo.all()
  end

  ## Private Cardigann Helpers

  defp apply_cardigann_filters(query, []), do: query

  defp apply_cardigann_filters(query, [{:type, type} | rest]) when is_binary(type) do
    query
    |> where([d], d.type == ^type)
    |> apply_cardigann_filters(rest)
  end

  defp apply_cardigann_filters(query, [{:language, language} | rest]) when is_binary(language) do
    query
    |> where([d], d.language == ^language)
    |> apply_cardigann_filters(rest)
  end

  defp apply_cardigann_filters(query, [{:enabled, enabled} | rest]) when is_boolean(enabled) do
    query
    |> where([d], d.enabled == ^enabled)
    |> apply_cardigann_filters(rest)
  end

  defp apply_cardigann_filters(query, [{:search, search_term} | rest])
       when is_binary(search_term) do
    search_pattern = "%#{String.downcase(search_term)}%"

    query
    |> where(
      [d],
      like(fragment("lower(?)", d.name), ^search_pattern) or
        like(fragment("lower(?)", d.description), ^search_pattern)
    )
    |> apply_cardigann_filters(rest)
  end

  defp apply_cardigann_filters(query, [_unknown | rest]) do
    apply_cardigann_filters(query, rest)
  end
end
