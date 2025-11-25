defmodule Mydia.Repo.Migrations.CreateConfigTables do
  use Ecto.Migration

  def change do
    # General configuration settings table
    # Note: category validation is handled by Ecto changeset
    create table(:config_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :value, :text
      add :category, :string, null: false
      add :description, :text
      add :updated_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:config_settings, [:key])
    create index(:config_settings, [:category])

    # Download client configurations
    # Note: type and enabled validation handled by Ecto changeset
    create table(:download_client_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false
      add :enabled, :boolean, default: true
      add :priority, :integer, default: 1
      add :host, :string, null: false
      add :port, :integer, null: false
      add :use_ssl, :boolean, default: false
      add :url_base, :string
      add :username, :string
      add :password, :string
      add :api_key, :string
      add :category, :string
      add :download_directory, :string
      add :connection_settings, :text
      add :updated_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:download_client_configs, [:name])
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])

    # Indexer configurations
    # Note: type and enabled validation handled by Ecto changeset
    create table(:indexer_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false
      add :enabled, :boolean, default: true
      add :priority, :integer, default: 1
      add :base_url, :string, null: false
      add :api_key, :string
      add :indexer_ids, :text
      add :categories, :text
      add :rate_limit, :integer
      add :connection_settings, :text
      add :updated_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:indexer_configs, [:name])
    create index(:indexer_configs, [:enabled])
    create index(:indexer_configs, [:priority])
    create index(:indexer_configs, [:type])

    # Library paths
    # Note: type, monitored, and last_scan_status validation handled by Ecto changeset
    create table(:library_paths, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string, null: false
      add :type, :string, null: false
      add :monitored, :boolean, default: true
      add :scan_interval, :integer, default: 3600
      add :last_scan_at, :utc_datetime
      add :last_scan_status, :string
      add :last_scan_error, :text

      add :quality_profile_id,
          references(:quality_profiles, type: :binary_id, on_delete: :nilify_all)

      add :updated_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:library_paths, [:path])
    create index(:library_paths, [:monitored])
    create index(:library_paths, [:type])
    create index(:library_paths, [:quality_profile_id])
  end
end
