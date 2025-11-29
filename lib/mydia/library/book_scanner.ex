defmodule Mydia.Library.BookScanner do
  @moduledoc """
  Scans and processes book files in library paths.

  Handles:
  - Scanning for book files (.epub, .pdf, .mobi, etc.)
  - Extracting metadata from EPUB, PDF, and other formats
  - Creating Author, Book, and BookFile records
  - Matching files to existing library items
  """

  require Logger

  alias Mydia.{Books, Repo}
  alias Mydia.Books.{Author, Book, BookFile}
  alias Mydia.Library.Scanner
  alias Mydia.Settings.LibraryPath

  @doc """
  Processes scan results for a books library path.

  Takes the raw scan result and creates/updates book records in the database.
  """
  def process_scan_result(%LibraryPath{} = library_path, scan_result) do
    existing_files = Books.list_book_files(library_path_id: library_path.id)

    # Detect changes using the shared scanner logic
    changes = Scanner.detect_changes(scan_result, existing_files, library_path)

    Logger.info("Processing books library changes",
      new_files: length(changes.new_files),
      modified_files: length(changes.modified_files),
      deleted_files: length(changes.deleted_files)
    )

    # Process new files
    new_results = Enum.map(changes.new_files, &process_new_file(&1, library_path))

    # Process modified files (re-read metadata)
    Enum.each(changes.modified_files, &process_modified_file(&1, library_path))

    # Delete removed files
    Enum.each(changes.deleted_files, &delete_book_file/1)

    %{
      new_files: length(changes.new_files),
      modified_files: length(changes.modified_files),
      deleted_files: length(changes.deleted_files),
      new_results: new_results
    }
  end

  @doc """
  Extracts metadata from a book file.

  Supports EPUB, PDF, and filename-based extraction for other formats.
  """
  def extract_metadata(file_path) do
    extension = Path.extname(file_path) |> String.downcase()

    case extension do
      ".epub" -> extract_epub_metadata(file_path)
      ".pdf" -> extract_pdf_metadata(file_path)
      _ -> extract_filename_metadata(file_path)
    end
  end

  ## Private Functions

  defp process_new_file(file_info, library_path) do
    relative_path = Path.relative_to(file_info.path, library_path.path)

    # extract_metadata always returns {:ok, metadata} (falls back to filename parsing)
    {:ok, metadata} = extract_metadata(file_info.path)

    # Find or create author
    author = find_or_create_author(metadata)

    # Find or create book
    book = find_or_create_book(metadata, author)

    # Create book file record
    case create_book_file(file_info, relative_path, library_path, book) do
      {:ok, book_file} ->
        Logger.debug("Created book file record",
          path: relative_path,
          author: metadata.author,
          title: metadata.title
        )

        {:ok, book_file}

      {:error, changeset} ->
        Logger.error("Failed to create book file",
          path: relative_path,
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  defp process_modified_file(file_info, library_path) do
    relative_path = Path.relative_to(file_info.path, library_path.path)

    case Books.get_book_file_by_path(file_info.path) do
      nil ->
        # File was somehow not in DB, process as new
        process_new_file(file_info, library_path)

      book_file ->
        # Update size
        Books.update_book_file(book_file, %{size: file_info.size})
        Logger.debug("Updated book file", path: relative_path)
    end
  end

  defp delete_book_file(book_file) do
    case Books.delete_book_file(book_file) do
      {:ok, _} ->
        Logger.debug("Deleted book file record", id: book_file.id)

      {:error, reason} ->
        Logger.error("Failed to delete book file",
          id: book_file.id,
          reason: inspect(reason)
        )
    end
  end

  defp find_or_create_author(metadata) do
    author_name = metadata.author || "Unknown Author"

    # Try to find existing author by name
    case find_author_by_name(author_name) do
      nil ->
        {:ok, author} =
          Books.create_author(%{
            name: author_name,
            sort_name: generate_sort_name(author_name)
          })

        author

      author ->
        author
    end
  end

  defp find_author_by_name(name) do
    import Ecto.Query

    Author
    |> where([a], fragment("LOWER(?)", a.name) == ^String.downcase(name))
    |> Repo.one()
  end

  defp find_or_create_book(metadata, author) do
    title = metadata.title || "Unknown Title"

    # Try to find existing book by title and author, or by ISBN
    existing_book =
      find_book_by_isbn(metadata.isbn) ||
        find_book_by_isbn13(metadata.isbn13) ||
        find_book_by_title_and_author(title, author.id)

    case existing_book do
      nil ->
        {:ok, book} =
          Books.create_book(%{
            title: title,
            author_id: author.id,
            isbn: metadata.isbn,
            isbn13: metadata.isbn13,
            publisher: metadata.publisher,
            publish_date: parse_publish_date(metadata.publish_date),
            description: metadata.description,
            language: metadata.language,
            series_name: metadata.series_name,
            series_position: metadata.series_position
          })

        book

      book ->
        # Update with any new metadata
        update_book_metadata(book, metadata)
    end
  end

  defp find_book_by_isbn(nil), do: nil
  defp find_book_by_isbn(isbn), do: Books.get_book_by_isbn(isbn)

  defp find_book_by_isbn13(nil), do: nil
  defp find_book_by_isbn13(isbn13), do: Books.get_book_by_isbn13(isbn13)

  defp find_book_by_title_and_author(title, author_id) do
    import Ecto.Query

    Book
    |> where([b], b.author_id == ^author_id)
    |> where([b], fragment("LOWER(?)", b.title) == ^String.downcase(title))
    |> Repo.one()
  end

  defp update_book_metadata(book, metadata) do
    updates =
      %{}
      |> maybe_update(:isbn, book.isbn, metadata.isbn)
      |> maybe_update(:isbn13, book.isbn13, metadata.isbn13)
      |> maybe_update(:publisher, book.publisher, metadata.publisher)
      |> maybe_update(:description, book.description, metadata.description)
      |> maybe_update(:language, book.language, metadata.language)
      |> maybe_update(:series_name, book.series_name, metadata.series_name)
      |> maybe_update(:series_position, book.series_position, metadata.series_position)

    if map_size(updates) > 0 do
      {:ok, updated} = Books.update_book(book, updates)
      updated
    else
      book
    end
  end

  defp maybe_update(updates, _key, _current, nil), do: updates
  defp maybe_update(updates, key, nil, new_value), do: Map.put(updates, key, new_value)
  defp maybe_update(updates, _key, _current, _new_value), do: updates

  defp create_book_file(file_info, relative_path, library_path, book) do
    format = BookFile.detect_format(file_info.path)

    Books.create_book_file(%{
      path: file_info.path,
      relative_path: relative_path,
      size: file_info.size,
      format: format,
      library_path_id: library_path.id,
      book_id: book.id
    })
  end

  # EPUB metadata extraction using the OPF file inside the EPUB
  defp extract_epub_metadata(file_path) do
    import SweetXml

    case :zip.unzip(String.to_charlist(file_path), [:memory]) do
      {:ok, files} ->
        # Find the OPF file (usually content.opf or package.opf)
        opf_content = find_opf_content(files)

        case opf_content do
          nil ->
            # Fall back to filename parsing
            extract_filename_metadata(file_path)

          content ->
            parse_opf_metadata(content, file_path)
        end

      {:error, _reason} ->
        # Corrupted EPUB, fall back to filename
        extract_filename_metadata(file_path)
    end
  rescue
    _ ->
      # Any error, fall back to filename
      extract_filename_metadata(file_path)
  end

  defp find_opf_content(files) do
    # Look for container.xml to find OPF path
    container =
      Enum.find(files, fn {name, _} ->
        String.ends_with?(to_string(name), "container.xml")
      end)

    opf_path =
      case container do
        {_, content} ->
          import SweetXml

          try do
            content
            |> xpath(~x"//rootfile/@full-path"s)
          rescue
            _ -> nil
          end

        nil ->
          nil
      end

    # Find OPF content
    opf_file =
      if opf_path do
        Enum.find(files, fn {name, _} ->
          String.ends_with?(to_string(name), opf_path) or
            to_string(name) == opf_path
        end)
      else
        # Fallback: look for any .opf file
        Enum.find(files, fn {name, _} ->
          String.ends_with?(to_string(name), ".opf")
        end)
      end

    case opf_file do
      {_, content} -> content
      nil -> nil
    end
  end

  defp parse_opf_metadata(opf_content, file_path) do
    import SweetXml

    try do
      doc = opf_content

      title = doc |> xpath(~x"//dc:title/text()"so) |> clean_text()
      author = doc |> xpath(~x"//dc:creator/text()"so) |> clean_text()
      publisher = doc |> xpath(~x"//dc:publisher/text()"so) |> clean_text()
      description = doc |> xpath(~x"//dc:description/text()"so) |> clean_text()
      language = doc |> xpath(~x"//dc:language/text()"so) |> clean_text()
      publish_date = doc |> xpath(~x"//dc:date/text()"so) |> clean_text()

      # Try to get ISBN from identifiers
      identifiers = doc |> xpath(~x"//dc:identifier"l)
      isbn = extract_isbn_from_identifiers(identifiers)
      isbn13 = extract_isbn13_from_identifiers(identifiers)

      # Parse series from calibre meta tags
      {series_name, series_position} = extract_series_info(doc)

      metadata = %{
        title: title,
        author: author,
        publisher: publisher,
        description: description,
        language: language,
        publish_date: publish_date,
        isbn: isbn,
        isbn13: isbn13,
        series_name: series_name,
        series_position: series_position,
        filename: Path.basename(file_path)
      }

      {:ok, metadata}
    rescue
      _ ->
        extract_filename_metadata(file_path)
    end
  end

  defp extract_isbn_from_identifiers(identifiers) do
    import SweetXml

    Enum.find_value(identifiers, fn id ->
      scheme = xpath(id, ~x"./@opf:scheme"so) || xpath(id, ~x"./@scheme"so) || ""
      value = xpath(id, ~x"./text()"so) || ""

      cond do
        String.downcase(scheme) == "isbn" and String.length(value) == 10 ->
          clean_isbn(value)

        String.match?(value, ~r/^(urn:isbn:)?[0-9X]{10}$/i) ->
          value |> String.replace(~r/^urn:isbn:/i, "") |> clean_isbn()

        true ->
          nil
      end
    end)
  end

  defp extract_isbn13_from_identifiers(identifiers) do
    import SweetXml

    Enum.find_value(identifiers, fn id ->
      scheme = xpath(id, ~x"./@opf:scheme"so) || xpath(id, ~x"./@scheme"so) || ""
      value = xpath(id, ~x"./text()"so) || ""

      cond do
        String.downcase(scheme) == "isbn" and String.length(String.replace(value, "-", "")) == 13 ->
          clean_isbn13(value)

        String.match?(value, ~r/^(urn:isbn:)?[0-9]{13}$/i) ->
          value |> String.replace(~r/^urn:isbn:/i, "") |> clean_isbn13()

        true ->
          nil
      end
    end)
  end

  defp extract_series_info(doc) do
    import SweetXml

    # Calibre stores series info in meta tags
    series_name = doc |> xpath(~x"//meta[@name='calibre:series']/@content"so) |> clean_text()

    series_index =
      doc |> xpath(~x"//meta[@name='calibre:series_index']/@content"so) |> clean_text()

    series_position =
      case series_index do
        nil ->
          nil

        "" ->
          nil

        idx ->
          case Float.parse(idx) do
            {pos, _} -> pos
            :error -> nil
          end
      end

    {series_name, series_position}
  end

  defp clean_isbn(value) do
    cleaned = value |> String.replace(~r/[^0-9X]/i, "") |> String.upcase()
    if String.length(cleaned) == 10, do: cleaned, else: nil
  end

  defp clean_isbn13(value) do
    cleaned = value |> String.replace(~r/[^0-9]/, "")
    if String.length(cleaned) == 13, do: cleaned, else: nil
  end

  defp clean_text(nil), do: nil

  defp clean_text(text) when is_binary(text) do
    text
    |> String.trim()
    |> case do
      "" -> nil
      t -> t
    end
  end

  defp clean_text(_), do: nil

  # PDF metadata extraction using pdfinfo (from poppler-utils)
  defp extract_pdf_metadata(file_path) do
    case System.cmd("pdfinfo", [file_path], stderr_to_stdout: true) do
      {output, 0} ->
        parse_pdfinfo_output(output, file_path)

      {_, _} ->
        # pdfinfo failed, fall back to filename
        extract_filename_metadata(file_path)
    end
  rescue
    ErlangError ->
      # pdfinfo not installed
      extract_filename_metadata(file_path)
  end

  defp parse_pdfinfo_output(output, file_path) do
    lines = String.split(output, "\n")

    get_field = fn field_name ->
      Enum.find_value(lines, fn line ->
        case String.split(line, ":", parts: 2) do
          [^field_name, value] -> String.trim(value)
          _ -> nil
        end
      end)
    end

    title = get_field.("Title")
    author = get_field.("Author")

    # Fall back to filename if no title
    title = if title && title != "", do: title, else: nil
    author = if author && author != "", do: author, else: nil

    metadata = %{
      title: title,
      author: author,
      publisher: get_field.("Producer"),
      description: nil,
      language: nil,
      publish_date: parse_pdf_date(get_field.("CreationDate")),
      isbn: nil,
      isbn13: nil,
      series_name: nil,
      series_position: nil,
      filename: Path.basename(file_path)
    }

    # If we couldn't get title or author, try filename parsing
    if is_nil(title) and is_nil(author) do
      extract_filename_metadata(file_path)
    else
      {:ok, metadata}
    end
  end

  defp parse_pdf_date(nil), do: nil

  defp parse_pdf_date(date_str) do
    # PDF dates are usually in format like "Mon Dec 25 10:30:00 2023"
    # or "D:20231225103000+00'00'"
    cond do
      String.starts_with?(date_str, "D:") ->
        # PDF date format D:YYYYMMDDHHmmSS...
        case Regex.run(~r/D:(\d{4})(\d{2})(\d{2})/, date_str) do
          [_, year, month, day] ->
            "#{year}-#{month}-#{day}"

          _ ->
            nil
        end

      true ->
        # Try to extract year from other formats
        case Regex.run(~r/\b(19|20)\d{2}\b/, date_str) do
          [year] -> year
          _ -> nil
        end
    end
  end

  # Filename-based metadata extraction
  defp extract_filename_metadata(file_path) do
    filename = Path.basename(file_path, Path.extname(file_path))

    # Try to parse common patterns:
    # "Author - Title (Year)"
    # "Author - Series #1 - Title"
    # "Title - Author"
    # "Title"

    parsed = parse_book_filename(filename)

    {:ok,
     %{
       title: parsed.title,
       author: parsed.author,
       publisher: nil,
       description: nil,
       language: nil,
       publish_date: parsed.year,
       isbn: nil,
       isbn13: nil,
       series_name: parsed.series_name,
       series_position: parsed.series_position,
       filename: Path.basename(file_path)
     }}
  end

  defp parse_book_filename(filename) do
    # Clean up common patterns
    cleaned =
      filename
      # Remove [tags]
      |> String.replace(~r/\[.*?\]/, "")
      # Remove (epub) etc
      |> String.replace(~r/\(.*?epub.*?\)/i, "")
      |> String.replace(~r/_/, " ")
      |> String.trim()

    # Try "Author - Title" or "Author - Series #N - Title"
    case String.split(cleaned, " - ", parts: 3) do
      [author, series_and_title, title] ->
        # Could be Author - Series #N - Title
        {series_name, series_pos} = parse_series_from_part(series_and_title)

        if series_name do
          %{
            author: author,
            title: title,
            series_name: series_name,
            series_position: series_pos,
            year: nil
          }
        else
          # Treat as Author - Middle - Title
          %{author: author, title: title, series_name: nil, series_position: nil, year: nil}
        end

      [author, title] ->
        # Check if author contains series info
        {series_name, series_pos} = parse_series_from_part(title)
        title_clean = if series_name, do: String.replace(title, ~r/\s*#\d+\s*/, ""), else: title

        %{
          author: author,
          title: title_clean,
          series_name: series_name,
          series_position: series_pos,
          year: extract_year(filename)
        }

      [title] ->
        %{
          author: nil,
          title: title,
          series_name: nil,
          series_position: nil,
          year: extract_year(filename)
        }
    end
  end

  defp parse_series_from_part(text) do
    # Look for patterns like "Series Name #1" or "Series Name Book 1"
    case Regex.run(~r/^(.+?)\s*(?:#|Book\s*)(\d+(?:\.\d+)?)/i, text) do
      [_, series, number] ->
        case Float.parse(number) do
          {pos, _} -> {series, pos}
          :error -> {nil, nil}
        end

      _ ->
        {nil, nil}
    end
  end

  defp extract_year(text) do
    case Regex.run(~r/\(?(19|20)\d{2}\)?/, text) do
      [year] -> String.replace(year, ~r/[()]/, "")
      _ -> nil
    end
  end

  defp parse_publish_date(nil), do: nil

  defp parse_publish_date(date) when is_binary(date) do
    cond do
      String.match?(date, ~r/^\d{4}-\d{2}-\d{2}$/) ->
        case Date.from_iso8601(date) do
          {:ok, d} -> d
          _ -> nil
        end

      String.match?(date, ~r/^\d{4}$/) ->
        case Integer.parse(date) do
          {year, _} -> Date.new!(year, 1, 1)
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp parse_publish_date(_), do: nil

  defp generate_sort_name(name) do
    # For authors, we might want "Last, First" format
    # For now, just remove common prefixes
    name
    |> String.trim()
    |> String.replace(~r/^(The|A|An)\s+/i, "")
  end
end
