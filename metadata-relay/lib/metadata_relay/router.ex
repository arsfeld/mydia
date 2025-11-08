defmodule MetadataRelay.Router do
  @moduledoc """
  HTTP router for the metadata relay service.
  """

  use Plug.Router

  alias MetadataRelay.TMDB.Handler

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  # Health check endpoint
  get "/health" do
    response = %{
      status: "ok",
      service: "metadata-relay",
      version: MetadataRelay.version()
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  # TMDB Configuration
  get "/configuration" do
    handle_tmdb_request(conn, fn -> Handler.configuration() end)
  end

  # TMDB Movie Search
  get "/tmdb/movies/search" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.search_movies(params) end)
  end

  # TMDB TV Search
  get "/tmdb/tv/search" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.search_tv(params) end)
  end

  # TMDB Movie Details
  get "/tmdb/movies/:id" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_movie(id, params) end)
  end

  # TMDB TV Show Details
  get "/tmdb/tv/shows/:id" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_tv_show(id, params) end)
  end

  # TMDB Movie Images
  get "/tmdb/movies/:id/images" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_movie_images(id, params) end)
  end

  # TMDB TV Show Images
  get "/tmdb/tv/shows/:id/images" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_tv_images(id, params) end)
  end

  # TMDB TV Season Details
  get "/tmdb/tv/shows/:id/:season" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_season(id, season, params) end)
  end

  # TMDB Trending Movies
  get "/tmdb/movies/trending" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.trending_movies(params) end)
  end

  # TMDB Trending TV
  get "/tmdb/tv/trending" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.trending_tv(params) end)
  end

  # 404 catch-all
  match _ do
    send_resp(conn, 404, "Not found")
  end

  # Private helpers

  defp handle_tmdb_request(conn, handler_fn) do
    case handler_fn.() do
      {:ok, body} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(body))

      {:error, {:http_error, status, body}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(body))

      {:error, reason} ->
        error_response = %{
          error: "Internal server error",
          message: inspect(reason)
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(error_response))
    end
  end

  defp extract_query_params(conn) do
    conn.query_params
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
