defmodule Mydia.Repo.Migrations.AddEnhancedFieldsToQualityProfiles do
  use Ecto.Migration

  def change do
    alter table(:quality_profiles) do
      add :description, :text
      add :is_system, :boolean, default: false
      add :version, :integer, default: 1
      add :source_url, :string
      add :last_synced_at, :utc_datetime
      add :quality_standards, :text
      add :metadata_preferences, :text
      add :customizations, :text
    end

    # Add indexes for commonly queried fields
    create index(:quality_profiles, [:is_system])
    create index(:quality_profiles, [:version])
    # name index already exists from create_quality_profiles migration (as unique index)
  end
end
