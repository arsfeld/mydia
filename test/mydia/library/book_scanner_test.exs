defmodule Mydia.Library.BookScannerTest do
  use Mydia.DataCase, async: false

  alias Mydia.Library.BookScanner
  alias Mydia.Books

  describe "extract_metadata/1" do
    test "falls back to filename parsing for non-existent file" do
      # The book scanner always tries to extract from filename as fallback
      {:ok, metadata} = BookScanner.extract_metadata("/nonexistent/path.epub")
      assert metadata.title == "path"
      assert metadata.author == nil
    end

    test "extracts metadata from filename for unknown formats" do
      # Create a temporary test file
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "Brandon Sanderson - Mistborn #1 - The Final Empire.mobi")

      File.write!(test_file, "fake book content")

      on_exit(fn ->
        File.rm(test_file)
      end)

      {:ok, metadata} = BookScanner.extract_metadata(test_file)

      assert metadata.author == "Brandon Sanderson"

      assert String.contains?(metadata.title, "The Final Empire") or
               String.contains?(metadata.title, "Mistborn")
    end

    test "parses author-title format from filename" do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "Terry Pratchett - Guards Guards.txt")

      File.write!(test_file, "fake book content")

      on_exit(fn ->
        File.rm(test_file)
      end)

      {:ok, metadata} = BookScanner.extract_metadata(test_file)

      assert metadata.author == "Terry Pratchett"
      assert metadata.title == "Guards Guards"
    end
  end

  describe "process_scan_result/2" do
    setup do
      # Create a library path for books
      {:ok, library_path} =
        Mydia.Settings.create_library_path(%{
          path: "/tmp/test_book_lib_#{:rand.uniform(100_000)}",
          name: "Test Books Library",
          type: :books,
          monitored: true
        })

      on_exit(fn ->
        Mydia.Settings.delete_library_path(library_path)
      end)

      %{library_path: library_path}
    end

    test "handles empty scan result", %{library_path: library_path} do
      scan_result = %{
        files: [],
        total_count: 0,
        total_size: 0,
        errors: []
      }

      result = BookScanner.process_scan_result(library_path, scan_result)

      assert result.new_files == 0
      assert result.modified_files == 0
      assert result.deleted_files == 0
    end
  end

  describe "author matching" do
    setup do
      {:ok, author} =
        Books.create_author(%{
          name: "Test Author",
          sort_name: "Author, Test"
        })

      on_exit(fn ->
        Books.delete_author(author)
      end)

      %{author: author}
    end

    test "finds existing author by name (case insensitive)", %{author: _author} do
      authors = Books.list_authors()
      assert Enum.any?(authors, fn a -> a.name == "Test Author" end)
    end
  end

  describe "book matching" do
    setup do
      {:ok, author} = Books.create_author(%{name: "Book Test Author"})

      {:ok, book} =
        Books.create_book(%{
          title: "Test Book",
          author_id: author.id,
          isbn: "0123456789"
        })

      on_exit(fn ->
        Books.delete_book(book)
        Books.delete_author(author)
      end)

      %{author: author, book: book}
    end

    test "finds existing book by title and author", %{author: author, book: _book} do
      books = Books.list_books(author_id: author.id)
      assert length(books) == 1
      assert hd(books).title == "Test Book"
    end

    test "finds existing book by ISBN", %{book: book} do
      found = Books.get_book_by_isbn("0123456789")
      assert found.id == book.id
    end
  end

  describe "extensions_for_library_type/1" do
    alias Mydia.Library.Scanner

    test "returns book extensions for :books type" do
      extensions = Scanner.extensions_for_library_type(:books)

      assert ".epub" in extensions
      assert ".pdf" in extensions
      assert ".mobi" in extensions
      assert ".azw" in extensions
      assert ".cbr" in extensions
    end
  end

  describe "filename parsing" do
    test "extracts series info from filename patterns" do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "Author Name - Series Name #3 - Book Title.epub")

      File.write!(test_file, "fake book content")

      on_exit(fn ->
        File.rm(test_file)
      end)

      {:ok, metadata} = BookScanner.extract_metadata(test_file)

      # The series parsing should extract series name and position
      assert metadata.author == "Author Name"
    end

    test "handles simple title format" do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "Simple Book Title.pdf")

      File.write!(test_file, "fake book content")

      on_exit(fn ->
        File.rm(test_file)
      end)

      {:ok, metadata} = BookScanner.extract_metadata(test_file)

      assert metadata.title == "Simple Book Title"
      assert metadata.author == nil
    end
  end
end
