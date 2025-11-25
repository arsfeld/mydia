defmodule Mydia.Repo.Migrations.AddCrashReportingToConfigSettingsCategory do
  @moduledoc """
  This migration originally added 'crash_reporting' to the allowed category values
  CHECK constraint on config_settings.

  Since we've moved constraint validation to the application layer (Ecto changesets),
  this migration is now a no-op. Category validation is enforced by the ConfigSetting
  schema's changeset validation.
  """
  use Ecto.Migration

  def change do
    # No-op: CHECK constraint validation moved to application layer
    # Category validation is now enforced by Ecto changeset in ConfigSetting schema
  end
end
