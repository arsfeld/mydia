defmodule Mydia.Repo.Migrations.CreateMediaRequests do
  use Ecto.Migration

  def change do
    # Note: status and media_type validation is enforced by Ecto changeset
    create table(:media_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :media_type, :string, null: false
      add :title, :string, null: false
      add :original_title, :string
      add :year, :integer
      add :tmdb_id, :integer
      add :imdb_id, :string
      add :status, :string, null: false, default: "pending"
      add :requester_notes, :text
      add :admin_notes, :text
      add :rejection_reason, :text
      add :approved_at, :utc_datetime
      add :rejected_at, :utc_datetime

      add :requester_id, references(:users, type: :binary_id, on_delete: :restrict), null: false
      add :approved_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :media_item_id, references(:media_items, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:media_requests, [:requester_id])
    create index(:media_requests, [:status])
    create index(:media_requests, [:tmdb_id])
    create index(:media_requests, [:media_type])
    create index(:media_requests, [:approved_by_id])
    create index(:media_requests, [:media_item_id])

    # Composite index for duplicate detection
    create index(:media_requests, [:tmdb_id, :status])
    create index(:media_requests, [:imdb_id, :status])
  end
end
