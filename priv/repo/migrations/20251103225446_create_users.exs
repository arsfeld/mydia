defmodule Mydia.Repo.Migrations.CreateUsers do
  @moduledoc """
  Creates the users table.

  NOTE: This migration was originally at timestamp 20251104023005 but was renamed
  to 20251103225446 to fix foreign key ordering (must run before config_tables).

  For existing users with the old timestamp, the table already exists and this
  migration uses `create_if_not_exists` to skip table creation gracefully.
  The old timestamp entry in schema_migrations will remain but is harmless.
  """
  use Ecto.Migration

  def change do
    # Note: role validation is enforced by Ecto changeset
    # Use create_if_not_exists to handle existing databases that already have this table
    # from the original 20251104023005 timestamp
    create_if_not_exists table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string
      add :email, :string
      add :password_hash, :string
      add :oidc_sub, :string
      add :oidc_issuer, :string
      add :role, :string, null: false, default: "user"
      add :display_name, :string
      add :avatar_url, :string
      add :last_login_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:users, [:username])
    create_if_not_exists unique_index(:users, [:email])
    create_if_not_exists unique_index(:users, [:oidc_sub])
    create_if_not_exists index(:users, [:oidc_sub, :oidc_issuer])
  end
end
