defmodule Mydia.Books.BookFile do
  @moduledoc """
  Schema for book files (ebook files on disk).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @book_formats ~w(epub pdf mobi azw azw3 cbr cbz txt djvu fb2 lit pdb rtf doc docx)

  schema "book_files" do
    field :path, :string
    field :relative_path, :string
    field :size, :integer
    field :format, :string

    belongs_to :book, Mydia.Books.Book
    belongs_to :library_path, Mydia.Settings.LibraryPath

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a book file.
  """
  def changeset(book_file, attrs) do
    book_file
    |> cast(attrs, [:path, :relative_path, :size, :format, :book_id, :library_path_id])
    |> validate_required([:path])
    |> validate_inclusion(:format, @book_formats)
    |> unique_constraint(:path)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:library_path_id)
  end

  @doc """
  Returns the list of supported book formats.
  """
  def valid_formats, do: @book_formats

  @doc """
  Detects the format from a file path extension.
  """
  def detect_format(path) when is_binary(path) do
    extension =
      path
      |> Path.extname()
      |> String.downcase()
      |> String.trim_leading(".")

    if extension in @book_formats, do: extension, else: nil
  end

  def detect_format(_), do: nil
end
