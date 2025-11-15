defmodule Mydia.CrashReporter.LoggerBackend do
  @moduledoc """
  Logger backend for automatic crash report capture.

  When crash reporting is enabled, this backend captures error and warning level
  log messages and sends them to the crash reporter for sanitization and transmission
  to the metadata relay.

  ## Configuration

  This backend is automatically started when the application starts, but only
  captures and reports errors when crash reporting is enabled.

  ## Features
  - Captures :error and :warning level messages
  - Filters out noise (e.g., test failures, expected errors)
  - Rate limiting to prevent spam
  - Async reporting (doesn't block the Logger)
  """

  @behaviour :gen_event

  require Logger

  @rate_limit_window 60_000
  @max_reports_per_window 10

  # gen_event callbacks

  @impl true
  def init(_opts) do
    # Initialize state
    state = %{
      reports_sent: %{},
      last_cleanup: System.monotonic_time(:millisecond)
    }

    {:ok, state}
  end

  @impl true
  def handle_event({level, _gl, {Logger, msg, _ts, metadata}}, state)
      when level in [:error, :warning] do
    # Only report if crash reporting is enabled
    if Mydia.CrashReporter.enabled?() do
      state = maybe_cleanup_rate_limits(state)

      if should_report?(msg, metadata, state) do
        # Extract error information from the log message
        case extract_error_info(msg, metadata) do
          {:ok, error, stacktrace} ->
            # Report the error asynchronously
            Task.start(fn ->
              Mydia.CrashReporter.report(error, stacktrace, build_metadata(metadata))
            end)

            # Update rate limit state
            new_state = record_report(state)
            {:ok, new_state}

          :skip ->
            {:ok, state}
        end
      else
        {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_event(_event, state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:configure, _opts}, state) do
    {:ok, :ok, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:ok, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end

  # Private functions

  defp should_report?(_msg, metadata, state) do
    # Don't report if we've hit the rate limit
    # Don't report test-related errors
    # Don't report errors from tests
    not rate_limited?(state) and
      not test_error?(metadata) and
      not in_test_env?()
  end

  defp rate_limited?(state) do
    recent_reports = Map.get(state.reports_sent, :count, 0)
    recent_reports >= @max_reports_per_window
  end

  defp test_error?(metadata) do
    # Check if this is a test-related error
    case Keyword.get(metadata, :file) do
      nil ->
        false

      file when is_list(file) ->
        file_str = to_string(file)
        String.contains?(file_str, "_test.exs") or String.contains?(file_str, "test/")

      file when is_binary(file) ->
        String.contains?(file, "_test.exs") or String.contains?(file, "test/")

      _ ->
        false
    end
  end

  defp in_test_env? do
    Application.get_env(:mydia, :environment) == :test or
      (Code.ensure_loaded?(Mix) and Mix.env() == :test)
  end

  defp extract_error_info(msg, metadata) do
    # Try to extract error and stacktrace from the log message
    cond do
      # Check if there's a crash_reason in metadata (from GenServer/Task crashes)
      Keyword.has_key?(metadata, :crash_reason) ->
        {error, stacktrace} = Keyword.get(metadata, :crash_reason)
        {:ok, error, stacktrace || []}

      # Check if there's an error in metadata
      Keyword.has_key?(metadata, :error) ->
        error = Keyword.get(metadata, :error)
        stacktrace = Keyword.get(metadata, :stacktrace, [])

        error_struct =
          if is_exception(error) do
            error
          else
            %RuntimeError{message: inspect(error)}
          end

        {:ok, error_struct, stacktrace}

      # If the message looks like an error report, create a generic error
      is_binary(msg) and (String.contains?(msg, "error") or String.contains?(msg, "Error")) ->
        error = %RuntimeError{message: to_string(msg)}
        stacktrace = build_stacktrace_from_metadata(metadata)
        {:ok, error, stacktrace}

      # Skip if we can't extract error info
      true ->
        :skip
    end
  end

  defp build_stacktrace_from_metadata(metadata) do
    # Try to build a stacktrace from metadata
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line)
    function = Keyword.get(metadata, :function)

    cond do
      file && line ->
        [{:unknown, function || :unknown, 0, [file: file, line: line]}]

      true ->
        []
    end
  end

  defp build_metadata(log_metadata) do
    # Extract relevant metadata for the crash report
    %{
      log_level: Keyword.get(log_metadata, :level),
      module: Keyword.get(log_metadata, :module),
      function: Keyword.get(log_metadata, :function),
      file: extract_file(Keyword.get(log_metadata, :file)),
      line: Keyword.get(log_metadata, :line),
      request_id: Keyword.get(log_metadata, :request_id)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp extract_file(file) when is_list(file), do: to_string(file)
  defp extract_file(file) when is_binary(file), do: file
  defp extract_file(_), do: nil

  defp record_report(state) do
    count = Map.get(state.reports_sent, :count, 0)
    %{state | reports_sent: %{count: count + 1}}
  end

  defp maybe_cleanup_rate_limits(state) do
    now = System.monotonic_time(:millisecond)

    if now - state.last_cleanup > @rate_limit_window do
      # Reset the counter
      %{state | reports_sent: %{}, last_cleanup: now}
    else
      state
    end
  end
end
