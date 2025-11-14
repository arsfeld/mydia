defmodule Mydia.Metadata.Structs.SearchResult do
  @moduledoc """
  Represents a search result from TMDB via the metadata relay service.

  This struct provides compile-time safety for search result data, replacing
  plain map access that can silently return nil.
  """

  @enforce_keys [:provider_id, :provider, :media_type]
  defstruct [
    # Required fields
    :provider_id,
    :provider,
    :media_type,
    # Optional fields
    :title,
    :name,
    :original_title,
    :original_name,
    :year,
    :release_date,
    :first_air_date,
    :poster_path,
    :backdrop_path,
    :id,
    :imdb_id,
    :overview,
    :popularity,
    :vote_average,
    :vote_count
  ]

  @type t :: %__MODULE__{
          provider_id: String.t(),
          provider: atom(),
          media_type: :movie | :tv_show,
          title: String.t() | nil,
          name: String.t() | nil,
          original_title: String.t() | nil,
          original_name: String.t() | nil,
          year: integer() | nil,
          release_date: Date.t() | String.t() | nil,
          first_air_date: Date.t() | String.t() | nil,
          poster_path: String.t() | nil,
          backdrop_path: String.t() | nil,
          id: integer() | nil,
          imdb_id: String.t() | nil,
          overview: String.t() | nil,
          popularity: float() | nil,
          vote_average: float() | nil,
          vote_count: integer() | nil
        }

  @doc """
  Creates a SearchResult struct from a raw API response map.

  ## Examples

      iex> from_api_response(%{"id" => 123, "title" => "The Matrix", ...})
      %SearchResult{provider_id: "123", title: "The Matrix", ...}
  """
  def from_api_response(data) when is_map(data) do
    media_type = normalize_media_type(data["media_type"])
    title = get_title(data, media_type)
    year = extract_year(data, media_type)

    %__MODULE__{
      provider_id: to_string(data["id"]),
      provider: :metadata_relay,
      title: title,
      original_title: data["original_title"] || data["original_name"],
      name: data["name"],
      original_name: data["original_name"],
      year: year,
      media_type: media_type,
      overview: data["overview"],
      poster_path: data["poster_path"],
      backdrop_path: data["backdrop_path"],
      popularity: data["popularity"],
      vote_average: data["vote_average"],
      vote_count: data["vote_count"],
      release_date: data["release_date"],
      first_air_date: data["first_air_date"],
      id: data["id"],
      imdb_id: data["imdb_id"]
    }
  end

  defp normalize_media_type("movie"), do: :movie
  defp normalize_media_type("tv"), do: :tv_show
  defp normalize_media_type(_), do: :movie

  defp get_title(data, :movie), do: data["title"] || data["name"]
  defp get_title(data, :tv_show), do: data["name"] || data["title"]
  defp get_title(data, _), do: data["title"] || data["name"]

  defp extract_year(data, :movie) do
    case data["release_date"] do
      nil -> nil
      date when is_binary(date) -> extract_year_from_date(date)
      _ -> nil
    end
  end

  defp extract_year(data, :tv_show) do
    case data["first_air_date"] do
      nil -> nil
      date when is_binary(date) -> extract_year_from_date(date)
      _ -> nil
    end
  end

  defp extract_year_from_date(date_string) do
    case String.split(date_string, "-") do
      [year | _] ->
        case Integer.parse(year) do
          {year_int, ""} -> year_int
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
