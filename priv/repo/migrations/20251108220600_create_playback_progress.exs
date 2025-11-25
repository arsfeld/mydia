defmodule Mydia.Repo.Migrations.CreatePlaybackProgress do
  use Ecto.Migration

  def change do
    # Note: The constraint ensuring exactly one of media_item_id or episode_id is set
    # is enforced by Ecto changeset validation
    create table(:playback_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all)
      add :episode_id, references(:episodes, type: :binary_id, on_delete: :delete_all)
      add :position_seconds, :integer, null: false
      add :duration_seconds, :integer, null: false
      add :completion_percentage, :float, null: false
      add :watched, :boolean, null: false, default: false
      add :last_watched_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    # Unique constraints for user + media_item and user + episode
    create unique_index(:playback_progress, [:user_id, :media_item_id],
             where: "media_item_id IS NOT NULL",
             name: :playback_progress_user_media_item_unique
           )

    create unique_index(:playback_progress, [:user_id, :episode_id],
             where: "episode_id IS NOT NULL",
             name: :playback_progress_user_episode_unique
           )

    create index(:playback_progress, [:user_id])
    create index(:playback_progress, [:media_item_id])
    create index(:playback_progress, [:episode_id])
    create index(:playback_progress, [:last_watched_at])
  end
end
