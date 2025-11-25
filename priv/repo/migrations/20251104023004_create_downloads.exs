defmodule Mydia.Repo.Migrations.CreateDownloads do
  use Ecto.Migration

  def change do
    # Note: status validation and progress range are enforced by Ecto changeset
    create table(:downloads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all)
      add :episode_id, references(:episodes, type: :binary_id, on_delete: :delete_all)
      add :status, :string, null: false
      add :indexer, :string
      add :title, :string, null: false
      add :download_url, :text
      add :download_client, :string
      add :download_client_id, :string
      add :progress, :float
      add :estimated_completion, :utc_datetime
      add :completed_at, :utc_datetime
      add :error_message, :text
      add :metadata, :text

      timestamps(type: :utc_datetime)
    end

    create index(:downloads, [:status])
    create index(:downloads, [:media_item_id])
    create index(:downloads, [:episode_id])
    create index(:downloads, [:inserted_at])
  end
end
