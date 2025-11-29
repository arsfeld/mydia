defmodule Mydia.Repo.Migrations.CreateBooksTables do
  use Ecto.Migration

  def change do
    # Authors table
    create table(:authors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :sort_name, :string
      add :openlibrary_id, :string
      add :goodreads_id, :string
      add :biography, :text
      add :image_url, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:authors, [:openlibrary_id], where: "openlibrary_id IS NOT NULL")
    create unique_index(:authors, [:goodreads_id], where: "goodreads_id IS NOT NULL")
    create index(:authors, [:name])
    create index(:authors, [:sort_name])

    # Books table
    create table(:books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :author_id, references(:authors, type: :binary_id, on_delete: :delete_all), null: false
      add :isbn, :string
      add :isbn13, :string
      add :openlibrary_id, :string
      add :goodreads_id, :string
      add :publish_date, :date
      add :publisher, :string
      add :pages, :integer
      add :language, :string
      add :description, :text
      add :cover_url, :string
      add :genres, {:array, :string}, default: []
      add :series_name, :string
      add :series_position, :float
      add :monitored, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:isbn], where: "isbn IS NOT NULL")
    create unique_index(:books, [:isbn13], where: "isbn13 IS NOT NULL")
    create unique_index(:books, [:openlibrary_id], where: "openlibrary_id IS NOT NULL")
    create index(:books, [:author_id])
    create index(:books, [:title])
    create index(:books, [:series_name, :series_position])

    # Book files table
    create table(:book_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all)
      add :library_path_id, references(:library_paths, type: :binary_id, on_delete: :nilify_all)
      add :path, :string, null: false
      add :relative_path, :string
      add :size, :bigint
      add :format, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:book_files, [:path])
    create index(:book_files, [:book_id])
    create index(:book_files, [:library_path_id])
    create index(:book_files, [:format])
  end
end
