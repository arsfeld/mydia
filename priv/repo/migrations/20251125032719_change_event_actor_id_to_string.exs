defmodule Mydia.Repo.Migrations.ChangeEventActorIdToString do
  use Ecto.Migration
  import Mydia.Repo.Migrations.Helpers

  @moduledoc """
  Change actor_id from binary_id (UUID) to string to support both:
  - UUIDs for user actors
  - Descriptive strings for system/job actors (e.g., "media_context", "download_monitor")

  PostgreSQL supports ALTER COLUMN TYPE directly.
  SQLite doesn't support ALTER COLUMN, so we recreate the table.
  """

  def up do
    if postgres?() do
      # PostgreSQL: simply alter the column type
      # UUIDs cast to text automatically
      execute "ALTER TABLE events ALTER COLUMN actor_id TYPE VARCHAR USING actor_id::text"
    else
      # SQLite: recreate the table
      sqlite_recreate_up()
    end
  end

  def down do
    if postgres?() do
      # PostgreSQL: change back to UUID
      # This will fail if non-UUID strings exist - which is expected
      execute "ALTER TABLE events ALTER COLUMN actor_id TYPE UUID USING actor_id::uuid"
    else
      # SQLite: recreate the table
      sqlite_recreate_down()
    end
  end

  defp sqlite_recreate_up do
    # Create new table with string actor_id
    create table(:events_new, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category, :string, null: false
      add :type, :string, null: false
      add :actor_type, :string
      add :actor_id, :string
      add :resource_type, :string
      add :resource_id, :binary_id
      add :severity, :string, null: false, default: "info"
      add :metadata, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Copy data - actor_id values (UUIDs) remain valid as strings
    execute """
    INSERT INTO events_new (id, category, type, actor_type, actor_id, resource_type, resource_id, severity, metadata, inserted_at)
    SELECT id, category, type, actor_type, actor_id, resource_type, resource_id, severity, metadata, inserted_at
    FROM events
    """

    # Drop old table
    drop table(:events)

    # Rename new table
    rename table(:events_new), to: table(:events)

    # Recreate indexes
    create index(:events, [:type])
    create index(:events, [:category])
    create index(:events, [:actor_type, :actor_id])
    create index(:events, [:resource_type, :resource_id])
    create index(:events, [:inserted_at])
    create index(:events, [:category, :type, :inserted_at])
  end

  defp sqlite_recreate_down do
    # Create table with original binary_id type
    create table(:events_new, primary_key: false) do
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

    # Copy data - only valid UUIDs will work, non-UUID strings will fail
    execute """
    INSERT INTO events_new (id, category, type, actor_type, actor_id, resource_type, resource_id, severity, metadata, inserted_at)
    SELECT id, category, type, actor_type, actor_id, resource_type, resource_id, severity, metadata, inserted_at
    FROM events
    """

    drop table(:events)
    rename table(:events_new), to: table(:events)

    create index(:events, [:type])
    create index(:events, [:category])
    create index(:events, [:actor_type, :actor_id])
    create index(:events, [:resource_type, :resource_id])
    create index(:events, [:inserted_at])
    create index(:events, [:category, :type, :inserted_at])
  end
end
