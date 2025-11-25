defmodule Mydia.Repo.Migrations.RelaxMediaFilesParentConstraint do
  @moduledoc """
  This migration originally relaxed the CHECK constraint on media_files
  to allow both media_item_id and episode_id to be NULL.

  Since we've moved constraint validation to the application layer (Ecto changesets),
  this migration is now a no-op. The parent constraint logic is enforced by the
  MediaFile schema's changeset validation.
  """
  use Ecto.Migration

  def change do
    # No-op: CHECK constraint validation moved to application layer
    # The constraint is now enforced by Ecto changeset in MediaFile schema
  end
end
