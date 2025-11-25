defmodule Mydia.Repo.Migrations.CreateMediaItems do
  use Ecto.Migration

  def change do
    # Note: type validation is handled by Ecto changeset
    create table(:media_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :title, :string, null: false
      add :original_title, :string
      add :year, :integer
      add :tmdb_id, :integer
      add :imdb_id, :string
      add :metadata, :text
      add :monitored, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:media_items, [:tmdb_id])
    create index(:media_items, [:imdb_id])
    create index(:media_items, [:title])
    create index(:media_items, [:type])
  end
end
