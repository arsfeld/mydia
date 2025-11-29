defmodule Mydia.Books do
  @moduledoc """
  The Books context handles book library functionality including authors and books.
  """

  import Ecto.Query, warn: false
  alias Mydia.Repo
  alias Mydia.Books.{Author, Book, BookFile}

  ## Authors

  @doc """
  Returns the list of authors.

  ## Options
    - `:preload` - List of associations to preload
    - `:search` - Search term for filtering by name
  """
  def list_authors(opts \\ []) do
    Author
    |> apply_author_filters(opts)
    |> order_by([a], asc: fragment("COALESCE(?, ?)", a.sort_name, a.name))
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Gets a single author.

  Raises `Ecto.NoResultsError` if the Author does not exist.
  """
  def get_author!(id, opts \\ []) do
    Author
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets an author by OpenLibrary ID.
  """
  def get_author_by_openlibrary(openlibrary_id) do
    Repo.get_by(Author, openlibrary_id: openlibrary_id)
  end

  @doc """
  Gets an author by Goodreads ID.
  """
  def get_author_by_goodreads(goodreads_id) do
    Repo.get_by(Author, goodreads_id: goodreads_id)
  end

  @doc """
  Creates an author.
  """
  def create_author(attrs \\ %{}) do
    %Author{}
    |> Author.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an author.
  """
  def update_author(%Author{} = author, attrs) do
    author
    |> Author.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an author.
  """
  def delete_author(%Author{} = author) do
    Repo.delete(author)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking author changes.
  """
  def change_author(%Author{} = author, attrs \\ %{}) do
    Author.changeset(author, attrs)
  end

  ## Books

  @doc """
  Returns the list of books.

  ## Options
    - `:preload` - List of associations to preload
    - `:author_id` - Filter by author ID
    - `:search` - Search term for filtering by title
    - `:monitored` - Filter by monitored status
    - `:series_name` - Filter by series name
  """
  def list_books(opts \\ []) do
    Book
    |> apply_book_filters(opts)
    |> order_by([b], asc: b.title)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Returns the count of books.
  """
  def count_books(opts \\ []) do
    Book
    |> apply_book_filters(opts)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.
  """
  def get_book!(id, opts \\ []) do
    Book
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets a book by ISBN.
  """
  def get_book_by_isbn(isbn) do
    Repo.get_by(Book, isbn: isbn)
  end

  @doc """
  Gets a book by ISBN-13.
  """
  def get_book_by_isbn13(isbn13) do
    Repo.get_by(Book, isbn13: isbn13)
  end

  @doc """
  Gets a book by OpenLibrary ID.
  """
  def get_book_by_openlibrary(openlibrary_id) do
    Repo.get_by(Book, openlibrary_id: openlibrary_id)
  end

  @doc """
  Creates a book.
  """
  def create_book(attrs \\ %{}) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book.
  """
  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.
  """
  def delete_book(%Book{} = book) do
    Repo.delete(book)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.
  """
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  @doc """
  Returns books grouped by series.
  """
  def list_books_by_series(opts \\ []) do
    Book
    |> apply_book_filters(opts)
    |> where([b], not is_nil(b.series_name))
    |> order_by([b], asc: b.series_name, asc: b.series_position)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
    |> Enum.group_by(& &1.series_name)
  end

  ## Book Files

  @doc """
  Returns the list of book files.

  ## Options
    - `:preload` - List of associations to preload
    - `:book_id` - Filter by book ID
    - `:library_path_id` - Filter by library path ID
    - `:format` - Filter by file format
  """
  def list_book_files(opts \\ []) do
    BookFile
    |> apply_book_file_filters(opts)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  @doc """
  Gets a single book file.

  Raises `Ecto.NoResultsError` if the BookFile does not exist.
  """
  def get_book_file!(id, opts \\ []) do
    BookFile
    |> maybe_preload(opts[:preload])
    |> Repo.get!(id)
  end

  @doc """
  Gets a book file by path.
  """
  def get_book_file_by_path(path) do
    Repo.get_by(BookFile, path: path)
  end

  @doc """
  Creates a book file.
  """
  def create_book_file(attrs \\ %{}) do
    %BookFile{}
    |> BookFile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book file.
  """
  def update_book_file(%BookFile{} = book_file, attrs) do
    book_file
    |> BookFile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book file.
  """
  def delete_book_file(%BookFile{} = book_file) do
    Repo.delete(book_file)
  end

  ## Helper Functions

  defp apply_author_filters(query, opts) do
    query
    |> filter_by_search(opts[:search], :name)
  end

  defp apply_book_filters(query, opts) do
    query
    |> filter_by_author_id(opts[:author_id])
    |> filter_by_monitored(opts[:monitored])
    |> filter_by_series(opts[:series_name])
    |> filter_by_search(opts[:search], :title)
  end

  defp apply_book_file_filters(query, opts) do
    query
    |> filter_by_book_id(opts[:book_id])
    |> filter_by_library_path_id(opts[:library_path_id])
    |> filter_by_format(opts[:format])
  end

  defp filter_by_search(query, nil, _field), do: query

  defp filter_by_search(query, search, field) do
    search_term = "%#{search}%"
    where(query, [q], ilike(field(q, ^field), ^search_term))
  end

  defp filter_by_author_id(query, nil), do: query
  defp filter_by_author_id(query, author_id), do: where(query, [q], q.author_id == ^author_id)

  defp filter_by_book_id(query, nil), do: query
  defp filter_by_book_id(query, book_id), do: where(query, [q], q.book_id == ^book_id)

  defp filter_by_library_path_id(query, nil), do: query

  defp filter_by_library_path_id(query, library_path_id),
    do: where(query, [q], q.library_path_id == ^library_path_id)

  defp filter_by_monitored(query, nil), do: query
  defp filter_by_monitored(query, monitored), do: where(query, [q], q.monitored == ^monitored)

  defp filter_by_series(query, nil), do: query
  defp filter_by_series(query, series_name), do: where(query, [q], q.series_name == ^series_name)

  defp filter_by_format(query, nil), do: query
  defp filter_by_format(query, format), do: where(query, [q], q.format == ^format)

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: preload(query, ^preloads)
end
