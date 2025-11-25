defmodule Mydia.Repo.Migrations.CreateImportSessions do
  use Ecto.Migration

  def change do
    # Note: step and status validation is enforced by Ecto changeset
    create table(:import_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :step, :string, null: false
      add :status, :string, null: false, default: "active"
      add :scan_path, :string
      add :session_data, :text
      add :scan_stats, :text
      add :import_progress, :text
      add :import_results, :text
      add :completed_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:import_sessions, [:user_id])
    create index(:import_sessions, [:status])
    create index(:import_sessions, [:expires_at])
  end
end
