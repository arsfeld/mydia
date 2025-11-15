defmodule Mydia.CrashReporter do
  @moduledoc """
  Privacy-focused crash reporter for Mydia.

  Stores application errors locally using ErrorTracker and optionally sends them to a
  metadata relay backend when users opt-in. All data sent to metadata-relay is sanitized.

  ## Features
  - Local crash storage via ErrorTracker (always enabled)
  - Optional sharing to metadata-relay (opt-in, disabled by default)
  - Automatic error capture via Logger backend when enabled
  - Manual error submission through admin interface
  - Privacy-focused sanitization for shared data (keeps debugging context)
  - Async report sending with local queue and retry logic
  - Layered configuration (environment variable + UI setting)

  ## Configuration

  Remote crash sharing to metadata-relay can be enabled in two ways:

  1. Environment variable (lower priority):
     ```bash
     CRASH_REPORTING_ENABLED=true
     ```

  2. Database/UI setting (higher priority):
     Via the admin interface or by setting "crash_reporting.enabled" in config_settings

  The UI setting always overrides the environment variable.

  ## Architecture

  **Local Storage (Always):**
  - All crashes stored in local ErrorTracker database
  - Viewable in Mydia admin interface
  - Retained for 30 days
  - Full error details with no sanitization

  **Metadata Relay (Opt-in):**
  - Sanitized crash reports sent to developer service
  - Helps developers diagnose issues across all Mydia instances
  - Only sent when user explicitly opts in
  - Data sanitized: usernames redacted, secrets removed, debugging context kept

  ## Privacy

  Crash reports sent to metadata-relay are sanitized:
  - Usernames in paths redacted (/home/user → /home/[USER])
  - Secrets and API keys removed
  - Passwords and credentials removed
  - File paths and IPs kept for debugging

  Local crash reports (in Mydia) contain full details for effective debugging.
  """

  require Logger

  alias Mydia.CrashReporter.{Sanitizer, Queue, Sender}

  @doc """
  Checks if crash reporting is enabled.

  The UI setting takes precedence over the environment variable.

  ## Examples

      iex> Mydia.CrashReporter.enabled?()
      false

  """
  @spec enabled?() :: boolean()
  def enabled? do
    # Check UI setting first (higher priority)
    case get_ui_setting() do
      {:ok, value} ->
        value

      :not_configured ->
        # Fall back to environment variable
        get_env_setting()
    end
  end

  @doc """
  Reports an error to the metadata relay.

  If crash reporting is disabled, this function is a no-op.
  If enabled, the error is sanitized and queued for async transmission.

  ## Parameters
  - `error`: The exception struct
  - `stacktrace`: The stacktrace (optional, defaults to current stacktrace)
  - `metadata`: Additional metadata (optional)

  ## Examples

      iex> Mydia.CrashReporter.report(%RuntimeError{message: "test"})
      :ok

  """
  @spec report(Exception.t(), keyword() | nil, map()) :: :ok | {:error, term()}
  def report(error, stacktrace \\ nil, metadata \\ %{}) do
    if enabled?() do
      do_report(error, stacktrace, metadata)
    else
      :ok
    end
  end

  @doc """
  Manually submits an error report.

  This function can be used even when automatic crash reporting is disabled.
  It's intended for manual report submission through the admin interface.

  ## Parameters
  - `error`: The exception struct
  - `stacktrace`: The stacktrace (optional)
  - `metadata`: Additional metadata (optional)

  ## Examples

      iex> Mydia.CrashReporter.submit_manual_report(%RuntimeError{message: "test"})
      {:ok, report_id}

  """
  @spec submit_manual_report(Exception.t(), keyword() | nil, map()) ::
          {:ok, String.t()} | {:error, term()}
  def submit_manual_report(error, stacktrace \\ nil, metadata \\ %{}) do
    do_report(error, stacktrace, metadata, manual: true)
  end

  @doc """
  Returns statistics about the crash reporter.

  ## Examples

      iex> Mydia.CrashReporter.stats()
      %{enabled: false, queued_reports: 0, sent_reports: 42}

  """
  @spec stats() :: map()
  def stats do
    %{
      enabled: enabled?(),
      queued_reports: Queue.count(),
      metadata_relay_url: get_metadata_relay_url()
    }
  end

  # Private functions

  defp do_report(error, stacktrace, metadata, opts \\ []) do
    stacktrace = stacktrace || get_current_stacktrace()

    # Report to local ErrorTracker first (always, for local viewing)
    ErrorTracker.report(error, stacktrace, metadata)

    # Also send to metadata-relay if opt-in is enabled
    if enabled?() or Keyword.get(opts, :manual, false) do
      # Build crash report for metadata-relay
      report = build_report(error, stacktrace, metadata)

      # Sanitize the report
      sanitized_report = Sanitizer.sanitize(report)

      # Queue for async sending to metadata-relay
      if Keyword.get(opts, :manual, false) do
        # For manual reports, send immediately and return result
        Sender.send_report(sanitized_report)
      else
        # For automatic reports, queue for async sending
        Queue.enqueue(sanitized_report)
        :ok
      end
    else
      :ok
    end
  end

  defp build_report(error, stacktrace, metadata) do
    %{
      error_type: error_type(error),
      error_message: Exception.message(error),
      stacktrace: format_stacktrace(stacktrace),
      version: Application.spec(:mydia, :vsn) |> to_string(),
      elixir_version: System.version(),
      otp_version: System.otp_release(),
      environment: Application.get_env(:mydia, :environment, "unknown") |> to_string(),
      occurred_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      metadata: metadata
    }
  end

  defp error_type(error) do
    error.__struct__
    |> Module.split()
    |> Enum.join(".")
  end

  defp format_stacktrace(stacktrace) do
    Enum.map(stacktrace, fn entry ->
      case entry do
        {module, function, arity, location} ->
          %{
            module: inspect(module),
            function: "#{function}/#{arity}",
            file: Keyword.get(location, :file) |> to_string(),
            line: Keyword.get(location, :line)
          }

        {module, function, arity} ->
          %{
            module: inspect(module),
            function: "#{function}/#{arity}",
            file: nil,
            line: nil
          }

        _ ->
          %{
            module: "unknown",
            function: "unknown",
            file: nil,
            line: nil
          }
      end
    end)
  end

  defp get_current_stacktrace do
    try do
      raise "stacktrace capture"
    catch
      :error, _ ->
        # Skip the first 3 frames (try/raise/this function)
        __STACKTRACE__
        |> Enum.drop(3)
    end
  end

  defp get_ui_setting do
    # Try to get the setting from the database
    # This queries the config_settings table for "crash_reporting.enabled"
    case Mydia.Settings.get_config_setting_by_key("crash_reporting.enabled") do
      nil ->
        :not_configured

      setting ->
        {:ok, parse_boolean(setting.value)}
    end
  rescue
    # If database is not available (e.g., during startup), fall back
    _ -> :not_configured
  end

  defp get_env_setting do
    case System.get_env("CRASH_REPORTING_ENABLED") do
      nil -> false
      value -> parse_boolean(value)
    end
  end

  defp parse_boolean(value) when is_boolean(value), do: value
  defp parse_boolean("true"), do: true
  defp parse_boolean("1"), do: true
  defp parse_boolean("yes"), do: true
  defp parse_boolean(_), do: false

  defp get_metadata_relay_url do
    Application.get_env(:mydia, :metadata_relay_url, "http://localhost:4001")
  end
end
