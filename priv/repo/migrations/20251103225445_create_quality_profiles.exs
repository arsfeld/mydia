defmodule Mydia.Repo.Migrations.CreateQualityProfiles do
  @moduledoc """
  Creates the quality_profiles table.

  NOTE: This migration was originally at timestamp 20251104023002 but was renamed
  to 20251103225445 to fix foreign key ordering (must run before config_tables).

  For existing users with the old timestamp, the table already exists and this
  migration uses `create_if_not_exists` to skip table creation gracefully.
  The old timestamp entry in schema_migrations will remain but is harmless.
  """
  use Ecto.Migration

  def change do
    # Use create_if_not_exists to handle existing databases that already have this table
    # from the original 20251104023002 timestamp
    create_if_not_exists table(:quality_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :upgrades_allowed, :boolean, default: true
      add :upgrade_until_quality, :string
      add :qualities, :text, null: false
      add :rules, :text

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:quality_profiles, [:name])
  end
end
