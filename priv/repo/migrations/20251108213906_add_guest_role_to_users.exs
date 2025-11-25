defmodule Mydia.Repo.Migrations.AddGuestRoleToUsers do
  @moduledoc """
  This migration originally added 'guest' to the allowed role values CHECK constraint.

  Since we've moved constraint validation to the application layer (Ecto changesets),
  this migration is now a no-op. Role validation is enforced by the User schema's
  changeset validation.
  """
  use Ecto.Migration

  def change do
    # No-op: CHECK constraint validation moved to application layer
    # Role validation is now enforced by Ecto changeset in User schema
  end
end
