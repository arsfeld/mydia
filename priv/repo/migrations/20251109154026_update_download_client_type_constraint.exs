defmodule Mydia.Repo.Migrations.UpdateDownloadClientTypeConstraint do
  @moduledoc """
  This migration originally added 'sabnzbd' and 'nzbget' to the allowed type values
  CHECK constraint on download_client_configs.

  Since we've moved constraint validation to the application layer (Ecto changesets),
  this migration is now a no-op. Type validation is enforced by the DownloadClientConfig
  schema's changeset validation.
  """
  use Ecto.Migration

  def change do
    # No-op: CHECK constraint validation moved to application layer
    # Type validation is now enforced by Ecto changeset in DownloadClientConfig schema
  end
end
