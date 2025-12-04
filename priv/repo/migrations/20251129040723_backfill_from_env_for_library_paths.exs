defmodule Mydia.Repo.Migrations.BackfillFromEnvForLibraryPaths do
  use Ecto.Migration
  import Mydia.Repo.Migrations.Helpers

  @moduledoc """
  Backfill from_env=true for all existing library paths.

  All existing library paths were created from environment variables,
  so we mark them as such. This enables the startup sync to properly
  disable library paths that are removed from the env config.
  """

  def up do
    execute_update(:library_paths, from_env: true)
  end

  def down do
    execute_update(:library_paths, from_env: false)
  end
end
