defmodule Mydia.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :media_item_id, references(:media_items, type: :binary_id, on_delete: :delete_all),
        null: false

      add :season_number, :integer, null: false
      add :episode_number, :integer, null: false
      add :title, :string
      add :air_date, :date
      add :metadata, :text
      add :monitored, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:episodes, [:media_item_id, :season_number, :episode_number])
    create index(:episodes, [:media_item_id])
    create index(:episodes, [:air_date])
  end
end
