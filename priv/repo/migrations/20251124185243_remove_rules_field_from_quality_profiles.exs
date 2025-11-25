defmodule Mydia.Repo.Migrations.RemoveRulesFieldFromQualityProfiles do
  use Ecto.Migration

  @moduledoc """
  Removes the deprecated `rules` field from the quality_profiles table.

  The rules field has been replaced by the more structured `quality_standards` field
  which provides separate size constraints for movies and episodes, along with other
  enhanced quality filtering capabilities.

  This migration should only run after the data migration task (20251124184927) has
  successfully converted all rules data to quality_standards.
  """

  def up do
    alter table(:quality_profiles) do
      remove :rules
    end
  end

  def down do
    alter table(:quality_profiles) do
      # Re-add rules field for rollback (original type was :text for JSON storage)
      add :rules, :text
    end
  end
end
