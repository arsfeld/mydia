defmodule Mydia.Repo.Migrations.CreateMediaFiles do
  use Ecto.Migration

  def change do
    # Note: The constraint ensuring exactly one of media_item_id or episode_id is set
    # is enforced by Ecto changeset validation
    create table(:media_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all)
      add :episode_id, references(:episodes, type: :binary_id, on_delete: :delete_all)
      add :path, :string, null: false
      add :size, :bigint
      add :quality_profile_id, references(:quality_profiles, type: :binary_id)
      add :resolution, :string
      add :codec, :string
      add :hdr_format, :string
      add :audio_codec, :string
      add :bitrate, :integer
      add :verified_at, :utc_datetime
      add :metadata, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:media_files, [:path])
    create index(:media_files, [:media_item_id])
    create index(:media_files, [:episode_id])
  end
end
