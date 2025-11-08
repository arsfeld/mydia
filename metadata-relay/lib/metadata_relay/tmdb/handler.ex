defmodule MetadataRelay.TMDB.Handler do
  @moduledoc """
  HTTP request handlers for TMDB API endpoints.

  Each function corresponds to a TMDB API endpoint and forwards
  the request to TMDB, returning the response.
  """

  alias MetadataRelay.TMDB.Client

  @doc """
  GET /configuration
  Returns TMDB API configuration including image base URLs.
  """
  def configuration do
    Client.get("/configuration")
  end

  @doc """
  GET /tmdb/movies/search
  Search for movies by title.
  """
  def search_movies(params) do
    Client.get("/search/movie", params: params)
  end

  @doc """
  GET /tmdb/tv/search
  Search for TV shows by title.
  """
  def search_tv(params) do
    Client.get("/search/tv", params: params)
  end

  @doc """
  GET /tmdb/movies/{id}
  Get movie details by ID.
  """
  def get_movie(id, params) do
    Client.get("/movie/#{id}", params: params)
  end

  @doc """
  GET /tmdb/tv/shows/{id}
  Get TV show details by ID.
  """
  def get_tv_show(id, params) do
    Client.get("/tv/#{id}", params: params)
  end

  @doc """
  GET /tmdb/movies/{id}/images
  Get images for a movie.
  """
  def get_movie_images(id, params) do
    Client.get("/movie/#{id}/images", params: params)
  end

  @doc """
  GET /tmdb/tv/shows/{id}/images
  Get images for a TV show.
  """
  def get_tv_images(id, params) do
    Client.get("/tv/#{id}/images", params: params)
  end

  @doc """
  GET /tmdb/tv/shows/{id}/{season_number}
  Get season details with episodes.
  """
  def get_season(show_id, season_number, params) do
    Client.get("/tv/#{show_id}/season/#{season_number}", params: params)
  end

  @doc """
  GET /tmdb/movies/trending
  Get trending movies.
  """
  def trending_movies(params) do
    Client.get("/trending/movie/week", params: params)
  end

  @doc """
  GET /tmdb/tv/trending
  Get trending TV shows.
  """
  def trending_tv(params) do
    Client.get("/trending/tv/week", params: params)
  end
end
