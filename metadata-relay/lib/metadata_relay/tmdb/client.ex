defmodule MetadataRelay.TMDB.Client do
  @moduledoc """
  HTTP client for TMDB API v3.

  This module provides a thin wrapper around the TMDB API using Req.
  It handles authentication and forwards requests to TMDB, returning
  the raw API responses.
  """

  @base_url "https://api.themoviedb.org/3"

  @doc """
  Creates a new Req client configured for TMDB API requests.

  Requires TMDB_API_KEY environment variable to be set.
  """
  def new do
    api_key = get_api_key()

    Req.new(
      base_url: @base_url,
      params: [api_key: api_key],
      headers: [
        {"accept", "application/json"},
        {"content-type", "application/json"}
      ]
    )
  end

  @doc """
  GET request to TMDB API.

  Returns `{:ok, response}` on success or `{:error, reason}` on failure.
  """
  def get(path, opts \\ []) do
    client = new()
    params = Keyword.get(opts, :params, [])

    case Req.get(client, url: path, params: params) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_api_key do
    case System.get_env("TMDB_API_KEY") do
      nil ->
        raise RuntimeError, """
        TMDB_API_KEY environment variable is not set.
        Please set it to your TMDB API key.
        """

      key ->
        key
    end
  end
end
