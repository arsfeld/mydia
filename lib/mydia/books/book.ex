defmodule Mydia.Books.Book do
  @moduledoc """
  Schema for books.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "books" do
    field :title, :string
    field :isbn, :string
    field :isbn13, :string
    field :openlibrary_id, :string
    field :goodreads_id, :string
    field :publish_date, :date
    field :publisher, :string
    field :pages, :integer
    field :language, :string
    field :description, :string
    field :cover_url, :string
    field :genres, {:array, :string}, default: []
    field :series_name, :string
    field :series_position, :float
    field :monitored, :boolean, default: true

    belongs_to :author, Mydia.Books.Author
    has_many :book_files, Mydia.Books.BookFile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a book.
  """
  def changeset(book, attrs) do
    book
    |> cast(attrs, [
      :title,
      :author_id,
      :isbn,
      :isbn13,
      :openlibrary_id,
      :goodreads_id,
      :publish_date,
      :publisher,
      :pages,
      :language,
      :description,
      :cover_url,
      :genres,
      :series_name,
      :series_position,
      :monitored
    ])
    |> validate_required([:title, :author_id])
    |> validate_number(:pages, greater_than: 0)
    |> validate_isbn(:isbn)
    |> validate_isbn13(:isbn13)
    |> unique_constraint(:isbn)
    |> unique_constraint(:isbn13)
    |> unique_constraint(:openlibrary_id)
    |> foreign_key_constraint(:author_id)
  end

  # Basic ISBN-10 validation (10 digits or 9 digits + X)
  defp validate_isbn(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if is_nil(value) or Regex.match?(~r/^[0-9]{9}[0-9X]$/, value) do
        []
      else
        [{field, "must be a valid ISBN-10 (10 characters)"}]
      end
    end)
  end

  # Basic ISBN-13 validation (13 digits)
  defp validate_isbn13(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if is_nil(value) or Regex.match?(~r/^[0-9]{13}$/, value) do
        []
      else
        [{field, "must be a valid ISBN-13 (13 digits)"}]
      end
    end)
  end
end
