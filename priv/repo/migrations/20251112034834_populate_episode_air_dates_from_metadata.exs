defmodule Mydia.Repo.Migrations.PopulateEpisodeAirDatesFromMetadata do
  @moduledoc """
  Populates air_date from the metadata JSON field for all episodes.
  Database-agnostic implementation using Elixir code.
  """
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Fetch all episodes with metadata but no air_date
    episodes =
      from(e in "episodes",
        where: is_nil(e.air_date) and not is_nil(e.metadata),
        select: %{id: e.id, metadata: e.metadata}
      )
      |> repo().all()

    # Update each episode's air_date from metadata
    Enum.each(episodes, fn episode ->
      case Jason.decode(episode.metadata || "{}") do
        {:ok, metadata} when is_map(metadata) ->
          air_date = metadata["air_date"]

          if air_date && air_date != "" do
            from(e in "episodes", where: e.id == ^episode.id)
            |> repo().update_all(set: [air_date: air_date])
          end

        _ ->
          :ok
      end
    end)
  end

  def down do
    # We don't want to clear air_dates on rollback since they should have been
    # populated correctly. This is a data fix migration.
    :ok
  end
end
