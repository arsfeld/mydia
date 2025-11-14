defmodule Mydia.Metadata.Structs.EpisodeData do
  @moduledoc """
  Represents episode data from TMDB via the metadata relay service.

  This struct provides compile-time safety for episode data, replacing
  plain map access that can silently return nil.
  """

  @enforce_keys [:season_number, :episode_number]
  defstruct [
    # Required fields
    :season_number,
    :episode_number,
    # Optional fields
    :name,
    :overview,
    :air_date,
    :runtime,
    :still_path,
    :vote_average,
    :vote_count
  ]

  @type t :: %__MODULE__{
          season_number: integer(),
          episode_number: integer(),
          name: String.t() | nil,
          overview: String.t() | nil,
          air_date: Date.t() | nil,
          runtime: integer() | nil,
          still_path: String.t() | nil,
          vote_average: float() | nil,
          vote_count: integer() | nil
        }

  @doc """
  Creates an EpisodeData struct from a raw API response map.

  ## Examples

      iex> from_api_response(%{"season_number" => 1, "episode_number" => 1, ...})
      %EpisodeData{season_number: 1, episode_number: 1, ...}
  """
  def from_api_response(data) when is_map(data) do
    %__MODULE__{
      season_number: data["season_number"],
      episode_number: data["episode_number"],
      name: data["name"],
      overview: data["overview"],
      air_date: parse_date(data["air_date"]),
      runtime: data["runtime"],
      still_path: data["still_path"],
      vote_average: data["vote_average"],
      vote_count: data["vote_count"]
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
