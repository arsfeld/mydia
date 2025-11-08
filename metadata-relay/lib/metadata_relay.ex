defmodule MetadataRelay do
  @moduledoc """
  MetadataRelay is a caching proxy service for TMDB and TVDB APIs.

  This service acts as a relay to prevent rate limiting and improve
  performance by caching metadata responses.
  """

  @doc """
  Returns the application version.
  """
  def version do
    Application.spec(:metadata_relay, :vsn) |> to_string()
  end
end
