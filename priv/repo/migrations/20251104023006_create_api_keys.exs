defmodule Mydia.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :key_hash, :string, null: false
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:api_keys, [:key_hash])
    create index(:api_keys, [:user_id])
  end
end
