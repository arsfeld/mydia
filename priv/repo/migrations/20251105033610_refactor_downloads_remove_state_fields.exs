defmodule Mydia.Repo.Migrations.RefactorDownloadsRemoveStateFields do
  use Ecto.Migration

  def change do
    # Remove state fields: status, progress, estimated_completion
    # Keep: completed_at and error_message for historical records

    # Drop the status index first (it was created in create_downloads)
    drop_if_exists index(:downloads, [:status])

    alter table(:downloads) do
      remove :status, :string
      remove :progress, :float
      remove :estimated_completion, :utc_datetime
    end

    # Add index on download_client_id
    create index(:downloads, [:download_client_id])
  end
end
