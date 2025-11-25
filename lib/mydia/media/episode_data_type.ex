defmodule Mydia.Media.EpisodeDataType do
  @moduledoc """
  Custom Ecto type for EpisodeData that provides full type safety.

  This type automatically converts between EpisodeData structs and plain maps
  during database operations, ensuring that all episode metadata fields are properly typed
  throughout the application.

  ## Benefits
  - Compile-time safety when accessing episode metadata fields
  - Automatic struct conversion on load/dump
  - Proper handling of Date fields (air_date)
  - Prevents silent nil returns from typos in field names

  ## Usage
  In your schema:

      schema "episodes" do
        field :metadata, Mydia.Media.EpisodeDataType
      end

  When you load an episode from the database, metadata will automatically
  be a %EpisodeData{} struct instead of a plain map.
  """

  use Ecto.Type

  alias Mydia.Metadata.Structs.EpisodeData

  @doc """
  Returns the underlying database type (:string for text columns).
  """
  def type, do: :string

  @doc """
  Casts the given value to an EpisodeData struct.

  Accepts:
  - EpisodeData struct (returns as-is)
  - Map with string keys (converts to EpisodeData)
  - Map with atom keys (converts to EpisodeData)
  - nil (returns nil)
  """
  def cast(%EpisodeData{} = episode_data), do: {:ok, episode_data}
  def cast(nil), do: {:ok, nil}

  def cast(data) when is_map(data) do
    {:ok, map_to_struct(data)}
  rescue
    e -> {:error, "Failed to cast to EpisodeData: #{inspect(e)}"}
  end

  def cast(_), do: :error

  @doc """
  Loads data from the database (JSON string) and converts to EpisodeData struct.
  """
  def load(nil), do: {:ok, nil}
  def load(""), do: {:ok, nil}

  def load(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, map} when is_map(map) -> {:ok, map_to_struct(map)}
      {:ok, _} -> :error
      {:error, _} -> :error
    end
  rescue
    e -> {:error, "Failed to load EpisodeData: #{inspect(e)}"}
  end

  # Handle case where data is already a map (some adapters may do this)
  def load(data) when is_map(data) do
    {:ok, map_to_struct(data)}
  rescue
    e -> {:error, "Failed to load EpisodeData: #{inspect(e)}"}
  end

  def load(_), do: :error

  @doc """
  Dumps an EpisodeData struct to a JSON string for database storage.
  """
  def dump(%EpisodeData{} = episode_data) do
    {:ok, Jason.encode!(struct_to_map(episode_data))}
  end

  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error

  # Converts a plain map (from DB) to EpisodeData struct
  defp map_to_struct(data) when is_map(data) do
    # Convert string keys to atom keys if needed
    data = atomize_keys(data)

    # Extract required fields
    season_number = data[:season_number]
    episode_number = data[:episode_number]

    %EpisodeData{
      season_number: season_number,
      episode_number: episode_number,
      name: data[:name],
      overview: data[:overview],
      air_date: parse_date(data[:air_date]),
      runtime: data[:runtime],
      still_path: data[:still_path],
      vote_average: data[:vote_average],
      vote_count: data[:vote_count]
    }
  end

  # Converts EpisodeData struct to plain map for DB storage
  defp struct_to_map(%EpisodeData{} = episode_data) do
    episode_data
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, convert_value_to_map(v)} end)
    |> Map.new()
  end

  # Convert Date structs to strings for DB storage
  defp convert_value_to_map(%Date{} = date), do: Date.to_iso8601(date)
  defp convert_value_to_map(value), do: value

  # Parse date strings to Date structs
  defp parse_date(nil), do: nil
  defp parse_date(%Date{} = date), do: date

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_), do: nil

  # Convert string keys to atom keys for easier access
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) ->
        # Try to convert to existing atom, fall back to creating new atom if needed
        atom_key =
          try do
            String.to_existing_atom(k)
          rescue
            ArgumentError -> String.to_atom(k)
          end

        {atom_key, v}

      {k, v} ->
        {k, v}
    end)
  end
end
