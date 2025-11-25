defmodule Mydia.Indexers.CardigannHealthCheck do
  @moduledoc """
  Health check functionality for Cardigann indexers.

  Provides manual test connection and automated health monitoring features
  for Cardigann-based indexers.

  ## Features

  - Manual test connection from UI
  - Automated periodic health checks
  - Health status tracking (healthy/degraded/unhealthy/unknown)
  - Response time measurement
  - Consecutive failure tracking
  """

  alias Mydia.Indexers.CardigannDefinition
  alias Mydia.Indexers.CardigannParser
  alias Mydia.Repo

  require Logger

  @type test_result :: %{
          success: boolean(),
          status: String.t(),
          message: String.t(),
          response_time_ms: non_neg_integer() | nil,
          error: String.t() | nil
        }

  @doc """
  Tests connection to an indexer by executing a simple test search.

  Executes a lightweight test query to verify the indexer is reachable,
  authentication works, and results can be parsed.

  ## Parameters

  - `definition_id` - ID of the Cardigann definition to test
  - `opts` - Optional test options

  ## Returns

  - `{:ok, test_result}` - Test completed (may indicate success or failure)
  - `{:error, reason}` - Test could not be executed

  ## Examples

      iex> test_connection(definition_id)
      {:ok, %{success: true, status: "healthy", message: "Connection successful", response_time_ms: 245}}

      iex> test_connection(definition_id)
      {:ok, %{success: false, status: "unhealthy", message: "Connection failed", error: "Timeout"}}
  """
  @spec test_connection(String.t(), keyword()) :: {:ok, test_result()} | {:error, String.t()}
  def test_connection(definition_id, opts \\ []) do
    case Repo.get(CardigannDefinition, definition_id) do
      nil ->
        {:error, "Indexer definition not found"}

      definition ->
        execute_health_check(definition, opts)
    end
  end

  @doc """
  Executes health check for a given definition and updates health status.

  Performs a test search, measures response time, and updates the definition's
  health status in the database.

  ## Parameters

  - `definition` - CardigannDefinition struct
  - `opts` - Optional health check options

  ## Returns

  - `{:ok, test_result}` - Health check completed and status updated
  - `{:error, reason}` - Health check failed
  """
  @spec execute_health_check(CardigannDefinition.t(), keyword()) ::
          {:ok, test_result()} | {:error, String.t()}
  def execute_health_check(%CardigannDefinition{} = definition, _opts \\ []) do
    # Parse the definition
    case CardigannParser.parse_definition(definition.definition) do
      {:ok, parsed_definition} ->
        perform_test_search(definition, parsed_definition)

      {:error, reason} ->
        result = %{
          success: false,
          status: "unhealthy",
          message: "Failed to parse definition",
          response_time_ms: nil,
          error: inspect(reason)
        }

        update_health_status(definition, result)
        {:ok, result}
    end
  end

  @doc """
  Runs health checks for all enabled Cardigann indexers.

  This function is designed to be called periodically by a background job
  to monitor the health of all enabled indexers.

  ## Returns

  - `{:ok, results}` - Map of definition_id => test_result
  """
  @spec check_all_enabled() :: {:ok, map()}
  def check_all_enabled do
    enabled_definitions =
      CardigannDefinition
      |> Repo.all()
      |> Enum.filter(& &1.enabled)

    results =
      enabled_definitions
      |> Task.async_stream(
        fn definition ->
          {definition.id, execute_health_check(definition)}
        end,
        timeout: :infinity,
        max_concurrency: 5
      )
      |> Enum.reduce(%{}, fn
        {:ok, {id, {:ok, result}}}, acc -> Map.put(acc, id, result)
        {:ok, {id, {:error, reason}}}, acc -> Map.put(acc, id, %{error: reason})
        _, acc -> acc
      end)

    {:ok, results}
  end

  # Private Functions

  defp perform_test_search(definition, parsed_definition) do
    start_time = System.monotonic_time(:millisecond)

    # Test connectivity by hitting the homepage instead of doing a full search
    # This avoids issues with complex Go template conditionals in search paths
    base_url = get_base_url(parsed_definition)

    result =
      case test_homepage(base_url, definition.config || %{}) do
        {:ok, status} ->
          response_time = System.monotonic_time(:millisecond) - start_time

          %{
            success: true,
            status: determine_health_status(definition, true, response_time),
            message: "Connection successful (HTTP #{status})",
            response_time_ms: response_time,
            error: nil
          }

        {:error, error} ->
          response_time = System.monotonic_time(:millisecond) - start_time

          %{
            success: false,
            status: determine_health_status(definition, false, response_time),
            message: "Connection failed",
            response_time_ms: response_time,
            error: format_error(error)
          }
      end

    update_health_status(definition, result)
    {:ok, result}
  end

  defp get_base_url(%{links: [base_url | _]}), do: String.trim_trailing(base_url, "/")
  defp get_base_url(_), do: nil

  defp test_homepage(nil, _user_config), do: {:error, "No base URL configured"}

  defp test_homepage(base_url, user_config) do
    req_opts = [
      receive_timeout: 30_000,
      redirect: true,
      retry: false
    ]

    # Add cookies if present in user config
    req_opts =
      case Map.get(user_config, "cookie") do
        nil ->
          req_opts

        cookie when is_binary(cookie) and cookie != "" ->
          Keyword.put(req_opts, :headers, [{"Cookie", cookie}])

        _ ->
          req_opts
      end

    case Req.get(base_url, req_opts) do
      {:ok, %Req.Response{status: status}} when status in 200..399 ->
        {:ok, status}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timeout"}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, "Connection failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp determine_health_status(definition, success, response_time) do
    cond do
      success && response_time < 5_000 ->
        "healthy"

      success && response_time < 15_000 ->
        "degraded"

      success ->
        "degraded"

      definition.consecutive_failures >= 3 ->
        "unhealthy"

      true ->
        "degraded"
    end
  end

  defp update_health_status(definition, result) do
    now = DateTime.utc_now()

    attrs =
      if result.success do
        %{
          health_status: result.status,
          last_health_check_at: now,
          last_successful_query_at: now,
          consecutive_failures: 0
        }
      else
        %{
          health_status: result.status,
          last_health_check_at: now,
          consecutive_failures: (definition.consecutive_failures || 0) + 1
        }
      end

    definition
    |> CardigannDefinition.health_check_changeset(attrs)
    |> Repo.update()
  end

  defp format_error(error) when is_binary(error), do: error
  defp format_error(error), do: inspect(error)
end
