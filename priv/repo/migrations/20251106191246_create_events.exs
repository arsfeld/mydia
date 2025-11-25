defmodule Mydia.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category, :string, null: false
      add :type, :string, null: false
      add :actor_type, :string
      add :actor_id, :binary_id
      add :resource_type, :string
      add :resource_id, :binary_id
      add :severity, :string, null: false, default: "info"
      add :metadata, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Index on type for filtering by specific event types
    create index(:events, [:type])

    # Index on category for filtering by event categories
    create index(:events, [:category])

    # Composite index on actor for filtering by actor
    create index(:events, [:actor_type, :actor_id])

    # Composite index on resource for filtering by resource
    create index(:events, [:resource_type, :resource_id])

    # Index on inserted_at for date-based queries and sorting
    create index(:events, [:inserted_at])

    # Composite index for common queries (category + type + time)
    create index(:events, [:category, :type, :inserted_at])
  end
end
