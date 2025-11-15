defmodule Mydia.CrashReporter.Sender do
  @moduledoc """
  Sends crash reports to the metadata relay backend.

  Handles the HTTP communication with the metadata relay crash report endpoint.
  Includes authentication, retry logic, and error handling.
  """

  require Logger

  @timeout 10_000

  @doc """
  Sends a crash report to the metadata relay.

  ## Parameters
  - `report`: The sanitized crash report map

  ## Returns
  - `{:ok, report_id}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> report = %{error_type: "RuntimeError", error_message: "test", stacktrace: []}
      iex> Mydia.CrashReporter.Sender.send_report(report)
      {:ok, "12345"}

  """
  @spec send_report(map()) :: {:ok, String.t()} | {:error, term()}
  def send_report(report) do
    url = get_crash_report_url()
    api_key = get_api_key()

    # Check if metadata relay is configured
    cond do
      url == "" ->
        {:error, :metadata_relay_not_configured}

      is_nil(api_key) or api_key == "" ->
        {:error, :api_key_not_configured}

      true ->
        send_http_request(url, api_key, report)
    end
  end

  # Private functions

  defp send_http_request(url, api_key, report) do
    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    body = Jason.encode!(report)

    case Req.post(url, headers: headers, body: body, receive_timeout: @timeout) do
      {:ok, %{status: 201, body: response}} ->
        # Successfully created
        Logger.debug("Crash report sent successfully", response: response)
        {:ok, extract_report_id(response)}

      {:ok, %{status: 400, body: response}} ->
        # Validation error
        Logger.warning("Crash report validation failed", response: response)
        {:error, {:validation_error, response}}

      {:ok, %{status: 401}} ->
        # Authentication failed
        Logger.error("Crash report authentication failed - check API key")
        {:error, :authentication_failed}

      {:ok, %{status: 429, headers: headers}} ->
        # Rate limited
        retry_after = get_retry_after(headers)
        Logger.warning("Crash report rate limited", retry_after: retry_after)
        {:error, {:rate_limited, retry_after}}

      {:ok, %{status: 503}} ->
        # Service unavailable
        Logger.warning("Metadata relay service unavailable")
        {:error, :service_unavailable}

      {:ok, %{status: status, body: body}} ->
        # Other error
        Logger.error("Crash report failed with unexpected status",
          status: status,
          body: inspect(body)
        )

        {:error, {:http_error, status, body}}

      {:error, %{reason: :timeout}} ->
        Logger.warning("Crash report request timed out")
        {:error, :timeout}

      {:error, %{reason: reason}} ->
        Logger.error("Crash report request failed", reason: inspect(reason))
        {:error, {:request_failed, reason}}

      {:error, reason} ->
        Logger.error("Crash report request failed", reason: inspect(reason))
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Crash report send failed with exception",
        error: Exception.message(error),
        stacktrace: __STACKTRACE__
      )

      {:error, {:exception, error}}
  end

  defp extract_report_id(response) when is_map(response) do
    Map.get(response, "id") || Map.get(response, :id) || "unknown"
  end

  defp extract_report_id(_), do: "unknown"

  defp get_retry_after(headers) do
    retry_header =
      Enum.find_value(headers, fn
        {"retry-after", value} -> value
        _ -> nil
      end)

    case retry_header do
      nil -> nil
      value when is_binary(value) -> String.to_integer(value)
      value when is_integer(value) -> value
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp get_crash_report_url do
    base_url = Application.get_env(:mydia, :metadata_relay_url, "http://localhost:4001")
    "#{base_url}/crashes/report"
  end

  defp get_api_key do
    Application.get_env(:mydia, :crash_report_api_key)
  end
end
