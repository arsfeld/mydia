defmodule Mydia.Indexers.CardigannResultParser do
  @moduledoc """
  Parser for Cardigann search results from HTML or JSON responses.

  This module handles parsing search results from HTTP responses using
  Cardigann selector definitions. It supports both HTML and JSON parsing
  with filters, transformations, and conversion to SearchResult structs.

  ## HTML Parsing

  Uses Floki for HTML parsing with CSS selector support:
  - Row selectors to identify result elements
  - Field selectors to extract data from each row
  - Attribute extraction (href, data-*, etc.)
  - Text content extraction

  ## JSON Parsing

  Supports JSONPath-style selectors for navigating JSON structures:
  - Object property access
  - Array indexing and iteration
  - Nested structure traversal

  ## Cardigann Filters

  Applies transformation filters defined in the Cardigann spec:
  - `replace` - String replacement
  - `re_replace` - Regex replacement
  - `append` - Append string
  - `prepend` - Prepend string
  - `trim` - Trim whitespace
  - `dateparse` - Parse date strings

  ## Examples

      # Parse HTML response
      definition = %Parsed{search: %{rows: %{selector: "tr.result"}, fields: ...}}
      response = %{status: 200, body: "<html>...</html>"}
      {:ok, results} = CardigannResultParser.parse_results(definition, response)

      # Parse JSON response
      definition = %Parsed{search: %{rows: %{selector: "$.results[*]"}, fields: ...}}
      response = %{status: 200, body: "{...}"}
      {:ok, results} = CardigannResultParser.parse_results(definition, response)
  """

  alias Mydia.Indexers.CardigannDefinition.Parsed
  alias Mydia.Indexers.SearchResult
  alias Mydia.Indexers.QualityParser
  alias Mydia.Indexers.Adapter.Error
  alias Mydia.Indexers.CardigannTemplate

  require Logger

  @type parse_result :: {:ok, [SearchResult.t()]} | {:error, Error.t()}
  @type http_response :: %{status: integer(), body: String.t()}

  @doc """
  Parses search results from an HTTP response using Cardigann definition.

  Automatically detects whether the response is HTML or JSON based on the
  response body and selectors defined in the definition.

  ## Parameters

  - `definition` - Parsed Cardigann definition with search configuration
  - `response` - HTTP response with status and body
  - `indexer_name` - Name of the indexer for result attribution
  - `opts` - Optional keyword list with:
    - `:template_context` - Template context for rendering filter arguments

  ## Returns

  - `{:ok, results}` - List of SearchResult structs
  - `{:error, reason}` - Parsing error

  ## Examples

      iex> parse_results(definition, response, "1337x")
      {:ok, [%SearchResult{}, ...]}

      iex> parse_results(definition, response, "1337x", template_context: %{config: %{"sort" => "seeders"}})
      {:ok, [%SearchResult{}, ...]}
  """
  @spec parse_results(Parsed.t(), http_response(), String.t(), keyword()) :: parse_result()
  def parse_results(%Parsed{} = definition, response, indexer_name, opts \\ []) do
    body = response.body
    template_context = Keyword.get(opts, :template_context, %{})

    # Guard against nil or non-string bodies
    cond do
      is_nil(body) ->
        {:error, Error.search_failed("Empty response body")}

      is_map(body) ->
        # Req auto-decoded JSON response - parse directly
        parse_json_results_from_map(definition, body, indexer_name, template_context)

      not is_binary(body) ->
        {:error, Error.search_failed("Invalid response body type: #{inspect(body)}")}

      String.trim(body) == "" ->
        {:ok, []}

      true ->
        case detect_response_type(body) do
          :html ->
            parse_html_results(definition, body, indexer_name, template_context)

          :json ->
            parse_json_results(definition, body, indexer_name, template_context)
        end
    end
  end

  @doc """
  Parses HTML response body using Cardigann selectors.

  ## Process

  1. Parse HTML with Floki
  2. Extract rows using row selector
  3. For each row, extract fields using field selectors
  4. Apply filters to field values (with template rendering)
  5. Transform to SearchResult structs

  ## Parameters

  - `definition` - Parsed Cardigann definition
  - `html_body` - HTML response body
  - `indexer_name` - Name of the indexer
  - `template_context` - Template context for rendering filter arguments

  ## Returns

  - `{:ok, results}` - List of SearchResult structs
  - `{:error, reason}` - Parsing error
  """
  @spec parse_html_results(Parsed.t(), String.t(), String.t(), map()) :: parse_result()
  def parse_html_results(%Parsed{} = definition, html_body, indexer_name, template_context \\ %{}) do
    with {:ok, document} <- parse_html_document(html_body),
         {:ok, rows} <- extract_rows(document, definition.search) do
      Logger.info("[#{indexer_name}] Extracted #{length(rows)} rows from HTML")

      case parse_row_fields(rows, definition.search, document, template_context) do
        {:ok, parsed_rows} ->
          Logger.info("[#{indexer_name}] Parsed #{length(parsed_rows)} rows successfully")
          results = transform_to_search_results(parsed_rows, indexer_name)
          Logger.info("[#{indexer_name}] Transformed to #{length(results)} search results")
          {:ok, results}

        error ->
          error
      end
    end
  rescue
    error ->
      Logger.error("HTML parsing error for #{indexer_name}: #{inspect(error)}")
      {:error, Error.search_failed("Failed to parse HTML response: #{inspect(error)}")}
  end

  @doc """
  Parses JSON response body using Cardigann selectors.

  ## Parameters

  - `definition` - Parsed Cardigann definition
  - `json_body` - JSON response body
  - `indexer_name` - Name of the indexer
  - `template_context` - Template context for rendering filter arguments

  ## Returns

  - `{:ok, results}` - List of SearchResult structs
  - `{:error, reason}` - Parsing error
  """
  @spec parse_json_results(Parsed.t(), String.t(), String.t(), map()) :: parse_result()
  def parse_json_results(%Parsed{} = definition, json_body, indexer_name, template_context \\ %{}) do
    with {:ok, json} <- Jason.decode(json_body),
         {:ok, rows} <- extract_json_rows(json, definition.search) do
      Logger.info("[#{indexer_name}] Extracted #{length(rows)} rows from JSON")

      case parse_json_row_fields(rows, definition.search, template_context) do
        {:ok, parsed_rows} ->
          Logger.info("[#{indexer_name}] Parsed #{length(parsed_rows)} JSON rows successfully")
          results = transform_to_search_results(parsed_rows, indexer_name)
          Logger.info("[#{indexer_name}] Transformed to #{length(results)} search results")
          {:ok, results}

        error ->
          error
      end
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, Error.search_failed("Invalid JSON: #{inspect(error)}")}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("JSON parsing error for #{indexer_name}: #{inspect(error)}")
      {:error, Error.search_failed("Failed to parse JSON response: #{inspect(error)}")}
  end

  @doc """
  Parses pre-decoded JSON response (when Req auto-decodes JSON).

  ## Parameters

  - `definition` - Parsed Cardigann definition
  - `json` - Already decoded JSON map
  - `indexer_name` - Name of the indexer
  - `template_context` - Template context for rendering filter arguments

  ## Returns

  - `{:ok, results}` - List of SearchResult structs
  - `{:error, reason}` - Parsing error
  """
  @spec parse_json_results_from_map(Parsed.t(), map(), String.t(), map()) :: parse_result()
  def parse_json_results_from_map(
        %Parsed{} = definition,
        json,
        indexer_name,
        template_context \\ %{}
      )
      when is_map(json) do
    with {:ok, rows} <- extract_json_rows(json, definition.search),
         {:ok, parsed_rows} <- parse_json_row_fields(rows, definition.search, template_context) do
      results = transform_to_search_results(parsed_rows, indexer_name)
      {:ok, results}
    end
  rescue
    error ->
      Logger.error("JSON map parsing error: #{inspect(error)}")
      {:error, Error.search_failed("Failed to parse JSON response: #{inspect(error)}")}
  end

  # HTML Parsing Functions

  defp parse_html_document(html_body) do
    case Floki.parse_document(html_body) do
      {:ok, document} -> {:ok, document}
      {:error, reason} -> {:error, Error.search_failed("HTML parse error: #{inspect(reason)}")}
    end
  end

  defp extract_rows(document, %{rows: %{selector: selector} = row_config}) do
    Logger.info("Extracting rows with selector: #{inspect(selector)}")
    rows = Floki.find(document, selector)
    Logger.info("Found #{length(rows)} rows before filtering")

    # Apply 'after' filter to skip header rows if configured
    rows_after_skip =
      case Map.get(row_config, :after) do
        nil ->
          rows

        skip_count when is_integer(skip_count) ->
          Logger.info("Skipping first #{skip_count} rows")
          Enum.drop(rows, skip_count)
      end

    {:ok, rows_after_skip}
  end

  defp extract_rows(_document, _search_config) do
    {:error, Error.search_failed("No row selector configured")}
  end

  defp parse_row_fields(rows, %{fields: fields}, _document, template_context) do
    parsed_rows =
      rows
      |> Enum.map(fn row ->
        parse_single_row(row, fields, template_context)
      end)
      |> Enum.filter(&(&1 != nil))

    {:ok, parsed_rows}
  end

  defp parse_single_row(row, fields, template_context) do
    field_values =
      Enum.reduce(fields, %{}, fn {field_name, field_config}, acc ->
        case extract_field_value(row, field_config, template_context) do
          {:ok, value} ->
            Map.put(acc, field_name, value)

          {:error, reason} ->
            # Field extraction failed, skip this field
            Logger.debug("Field #{field_name} extraction failed: #{inspect(reason)}")
            acc
        end
      end)

    # Only return row if we got at least title and download
    has_title = Map.has_key?(field_values, "title") || Map.has_key?(field_values, :title)
    has_download = Map.has_key?(field_values, "download") || Map.has_key?(field_values, :download)

    if has_title && has_download do
      field_values
    else
      Logger.info(
        "Row filtered out - title: #{has_title}, download: #{has_download}, fields: #{inspect(Map.keys(field_values))}"
      )

      nil
    end
  end

  defp extract_field_value(row, field_config, template_context) when is_map(field_config) do
    selector = Map.get(field_config, :selector) || Map.get(field_config, "selector")
    attribute = Map.get(field_config, :attribute) || Map.get(field_config, "attribute")
    filters = Map.get(field_config, :filters) || Map.get(field_config, "filters", [])

    with {:ok, raw_value} <- extract_raw_value(row, selector, attribute),
         {:ok, filtered_value} <- apply_filters(raw_value, filters, template_context) do
      {:ok, filtered_value}
    end
  end

  defp extract_raw_value(row, selector, nil) do
    # Extract text content
    case Floki.find(row, selector) do
      [] ->
        {:error, :not_found}

      elements ->
        text =
          elements
          |> Floki.text()
          |> String.trim()

        {:ok, text}
    end
  end

  defp extract_raw_value(row, selector, attribute) do
    # Extract attribute value
    case Floki.find(row, selector) do
      [] ->
        {:error, :not_found}

      elements ->
        case Floki.attribute(elements, attribute) do
          [value | _] -> {:ok, String.trim(value)}
          [] -> {:error, :not_found}
        end
    end
  end

  @doc """
  Applies Cardigann filters to a field value.

  Filters are applied in sequence, with each filter transforming
  the value before passing to the next filter. Filter arguments
  containing Go template syntax will be rendered using the provided
  template context before application.

  ## Supported Filters

  - `replace` - String replacement: `{name: "replace", args: ["old", "new"]}`
  - `re_replace` - Regex replacement: `{name: "re_replace", args: ["pattern", "replacement"]}`
  - `append` - Append string: `{name: "append", args: ["suffix"]}`
  - `prepend` - Prepend string: `{name: "prepend", args: ["prefix"]}`
  - `trim` - Trim whitespace: `{name: "trim"}`
  - `dateparse` - Parse date: `{name: "dateparse", args: ["format"]}`

  ## Examples

      iex> apply_filters("  test  ", [%{name: "trim"}], %{})
      {:ok, "test"}

      iex> apply_filters("1.5 GB", [%{name: "replace", args: [" GB", ""]}], %{})
      {:ok, "1.5"}

      iex> apply_filters("text", [%{name: "append", args: ["{{ if .Config.flag }} suffix{{ else }}{{ end }}"]}], %{config: %{"flag" => true}})
      {:ok, "text suffix"}
  """
  @spec apply_filters(String.t(), list(), map()) :: {:ok, String.t()} | {:error, term()}
  def apply_filters(value, [], _template_context), do: {:ok, value}

  def apply_filters(value, [filter | rest], template_context) do
    # Render templates in filter arguments
    rendered_filter = render_filter_templates(filter, template_context)

    case apply_single_filter(value, rendered_filter) do
      {:ok, new_value} -> apply_filters(new_value, rest, template_context)
      error -> error
    end
  end

  # Backward compatibility - allow calling without template_context
  def apply_filters(value, filters) when is_list(filters) do
    apply_filters(value, filters, %{})
  end

  # Renders Go templates in filter arguments using the provided template context
  defp render_filter_templates(filter, template_context) when is_map(filter) do
    # Get args from filter (support both atom and string keys)
    args = Map.get(filter, :args) || Map.get(filter, "args")
    args_key = if Map.has_key?(filter, :args), do: :args, else: "args"

    case args do
      nil ->
        filter

      args when is_list(args) ->
        # Render each arg that contains template syntax (if template_context available)
        rendered_args =
          if template_context == %{} or template_context == nil do
            args
          else
            Enum.map(args, fn arg ->
              render_template_in_string(arg, template_context)
            end)
          end

        Map.put(filter, args_key, rendered_args)

      args when is_binary(args) ->
        # Single string arg - render template (if context available) and wrap in list for consistency
        rendered_arg =
          if template_context == %{} or template_context == nil do
            args
          else
            render_template_in_string(args, template_context)
          end

        Map.put(filter, args_key, [rendered_arg])

      _ ->
        filter
    end
  end

  defp render_filter_templates(filter, _template_context), do: filter

  # Helper to render template in a string if it contains template syntax
  defp render_template_in_string(value, template_context) when is_binary(value) do
    if String.contains?(value, "{{") do
      case CardigannTemplate.render(value, template_context, url_encode: false) do
        {:ok, rendered} -> rendered
        {:error, _} -> value
      end
    else
      value
    end
  end

  defp render_template_in_string(value, _template_context), do: value

  defp apply_single_filter(value, %{name: "replace", args: [pattern, replacement]}) do
    {:ok, String.replace(value, pattern, replacement)}
  end

  defp apply_single_filter(value, %{"name" => "replace", "args" => [pattern, replacement]}) do
    {:ok, String.replace(value, pattern, replacement)}
  end

  defp apply_single_filter(value, %{name: "re_replace", args: [pattern, replacement]}) do
    case Regex.compile(pattern) do
      {:ok, regex} -> {:ok, Regex.replace(regex, value, replacement)}
      {:error, _} -> {:error, :invalid_regex}
    end
  end

  defp apply_single_filter(value, %{"name" => "re_replace", "args" => [pattern, replacement]}) do
    case Regex.compile(pattern) do
      {:ok, regex} -> {:ok, Regex.replace(regex, value, replacement)}
      {:error, _} -> {:error, :invalid_regex}
    end
  end

  defp apply_single_filter(value, %{name: "append", args: [suffix]}) do
    {:ok, value <> suffix}
  end

  defp apply_single_filter(value, %{"name" => "append", "args" => [suffix]}) do
    {:ok, value <> suffix}
  end

  defp apply_single_filter(value, %{name: "prepend", args: [prefix]}) do
    {:ok, prefix <> value}
  end

  defp apply_single_filter(value, %{"name" => "prepend", "args" => [prefix]}) do
    {:ok, prefix <> value}
  end

  defp apply_single_filter(value, %{name: "trim"}) do
    {:ok, String.trim(value)}
  end

  defp apply_single_filter(value, %{"name" => "trim"}) do
    {:ok, String.trim(value)}
  end

  defp apply_single_filter(value, _unknown_filter) do
    # Unknown filter, just pass through
    {:ok, value}
  end

  # JSON Parsing Functions

  defp extract_json_rows(json, %{rows: %{selector: selector}}) do
    case navigate_json_path(json, selector) do
      {:ok, rows} when is_list(rows) ->
        {:ok, rows}

      {:ok, single_value} ->
        {:ok, [single_value]}

      {:error, :path_not_found} ->
        # Log available keys to help diagnose the issue
        available_keys = if is_map(json), do: Map.keys(json), else: []

        Logger.warning(
          "JSON path not found: #{selector}. Available top-level keys: #{inspect(available_keys)}"
        )

        # Return empty results instead of failing
        {:ok, []}

      error ->
        error
    end
  end

  defp extract_json_rows(_json, _search_config) do
    {:error, Error.search_failed("No row selector configured for JSON")}
  end

  defp navigate_json_path(json, "$") do
    {:ok, json}
  end

  defp navigate_json_path(json, "$.") do
    {:ok, json}
  end

  defp navigate_json_path(json, "$." <> path) do
    navigate_json_path_parts(json, String.split(path, "."))
  end

  defp navigate_json_path(json, path) do
    # Assume it's a simple property name
    navigate_json_path_parts(json, [path])
  end

  defp navigate_json_path_parts(value, []) do
    {:ok, value}
  end

  defp navigate_json_path_parts(map, [key | rest]) when is_map(map) do
    case Map.get(map, key) do
      nil -> {:error, :path_not_found}
      value -> navigate_json_path_parts(value, rest)
    end
  end

  defp navigate_json_path_parts(_value, _path) do
    {:error, :invalid_path}
  end

  defp parse_json_row_fields(rows, %{fields: fields}, template_context) do
    parsed_rows =
      rows
      |> Enum.map(fn row ->
        parse_single_json_row(row, fields, template_context)
      end)
      |> Enum.filter(&(&1 != nil))

    {:ok, parsed_rows}
  end

  defp parse_single_json_row(row, fields, template_context) when is_map(row) do
    field_values =
      Enum.reduce(fields, %{}, fn {field_name, field_config}, acc ->
        case extract_json_field_value(row, field_config, template_context) do
          {:ok, value} ->
            Map.put(acc, field_name, value)

          {:error, _reason} ->
            acc
        end
      end)

    # Only return row if we got at least title and download
    if Map.has_key?(field_values, "title") && Map.has_key?(field_values, "download") do
      field_values
    else
      nil
    end
  end

  defp extract_json_field_value(row, field_config, template_context) when is_map(field_config) do
    selector = Map.get(field_config, :selector) || Map.get(field_config, "selector")
    filters = Map.get(field_config, :filters) || Map.get(field_config, "filters", [])

    with {:ok, raw_value} <- get_json_value_by_selector(row, selector),
         {:ok, str_value} <- ensure_string(raw_value),
         {:ok, filtered_value} <- apply_filters(str_value, filters, template_context) do
      {:ok, filtered_value}
    end
  end

  defp get_json_value_by_selector(row, selector) when is_binary(selector) do
    # Simple property access
    case Map.get(row, selector) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  defp ensure_string(value) when is_binary(value), do: {:ok, value}
  defp ensure_string(value) when is_integer(value), do: {:ok, Integer.to_string(value)}
  defp ensure_string(value) when is_float(value), do: {:ok, Float.to_string(value)}
  defp ensure_string(nil), do: {:error, :not_found}
  defp ensure_string(_), do: {:error, :invalid_type}

  # Result Transformation

  defp transform_to_search_results(parsed_rows, indexer_name) do
    parsed_rows
    |> Enum.map(fn row -> transform_to_search_result(row, indexer_name) end)
    |> Enum.filter(&(&1 != nil))
  end

  defp transform_to_search_result(row, indexer_name) do
    with {:ok, title} <- get_required_field(row, "title"),
         {:ok, download_url} <- get_required_field(row, "download"),
         size <- parse_size(get_field(row, "size", "0")),
         seeders <- parse_integer(get_field(row, "seeders", "0")),
         leechers <- parse_integer(get_field(row, "leechers", "0")) do
      # Parse quality from title
      quality = QualityParser.parse(title)

      # Build SearchResult
      %SearchResult{
        title: title,
        size: size,
        seeders: seeders,
        leechers: leechers,
        download_url: download_url,
        info_url: get_field(row, "details"),
        indexer: indexer_name,
        category: parse_integer(get_field(row, "category")),
        published_at: parse_date(get_field(row, "date")),
        quality: quality,
        tmdb_id: parse_integer(get_field(row, "tmdbid")),
        imdb_id: get_field(row, "imdbid")
      }
    else
      _ -> nil
    end
  end

  defp get_required_field(row, field) do
    case Map.get(row, field) do
      nil -> {:error, :missing_field}
      "" -> {:error, :empty_field}
      value -> {:ok, value}
    end
  end

  defp get_field(row, field, default \\ nil) do
    Map.get(row, field, default)
  end

  @doc """
  Parses size strings to bytes.

  Supports various formats:
  - "1.5 GB" → 1_610_612_736 bytes
  - "500 MB" → 524_288_000 bytes
  - "1024 KB" → 1_048_576 bytes
  - "1024" → 1024 bytes

  ## Examples

      iex> parse_size("1.5 GB")
      1_610_612_736

      iex> parse_size("500 MB")
      524_288_000
  """
  @spec parse_size(String.t() | nil) :: non_neg_integer()
  def parse_size(nil), do: 0
  def parse_size(""), do: 0

  def parse_size(size_str) when is_binary(size_str) do
    size_str = String.trim(size_str)

    cond do
      String.contains?(size_str, "GB") || String.contains?(size_str, "GiB") ->
        parse_size_value(size_str, 1024 * 1024 * 1024)

      String.contains?(size_str, "MB") || String.contains?(size_str, "MiB") ->
        parse_size_value(size_str, 1024 * 1024)

      String.contains?(size_str, "KB") || String.contains?(size_str, "KiB") ->
        parse_size_value(size_str, 1024)

      String.contains?(size_str, "TB") || String.contains?(size_str, "TiB") ->
        parse_size_value(size_str, 1024 * 1024 * 1024 * 1024)

      true ->
        # Assume it's already in bytes
        parse_integer(size_str)
    end
  end

  defp parse_size_value(size_str, multiplier) do
    # Extract numeric value from string
    numeric_part =
      size_str
      |> String.replace(~r/[^\d.]/, "")
      |> String.trim()

    case Float.parse(numeric_part) do
      {value, _} -> trunc(value * multiplier)
      :error -> 0
    end
  end

  defp parse_integer(nil), do: 0
  defp parse_integer(""), do: 0

  defp parse_integer(str) when is_binary(str) do
    # Remove any non-digit characters
    clean_str = String.replace(str, ~r/[^\d]/, "")

    case Integer.parse(clean_str) do
      {num, _} -> num
      :error -> 0
    end
  end

  defp parse_integer(num) when is_integer(num), do: num
  defp parse_integer(_), do: 0

  @doc """
  Parses date strings to DateTime.

  Attempts to parse various date formats:
  - ISO 8601: "2024-01-15T12:30:00Z"
  - Relative: "2 hours ago", "yesterday"
  - Custom formats based on common patterns

  ## Examples

      iex> parse_date("2024-01-15T12:30:00Z")
      ~U[2024-01-15 12:30:00Z]

      iex> parse_date(nil)
      nil
  """
  @spec parse_date(String.t() | nil) :: DateTime.t() | nil
  def parse_date(nil), do: nil
  def parse_date(""), do: nil

  def parse_date(date_str) when is_binary(date_str) do
    # Try ISO 8601 format first
    case DateTime.from_iso8601(date_str) do
      {:ok, datetime, _offset} ->
        datetime

      _ ->
        # Try other common formats using Timex
        case Timex.parse(date_str, "{ISO:Extended}") do
          {:ok, datetime} -> datetime
          _ -> nil
        end
    end
  rescue
    _ -> nil
  end

  # Response Type Detection

  defp detect_response_type(body) when is_binary(body) do
    trimmed = String.trim(body)

    cond do
      # Check if it looks like JSON (starts with { or [)
      String.starts_with?(trimmed, "{") || String.starts_with?(trimmed, "[") ->
        # Verify it's actually valid JSON before treating as JSON
        case Jason.decode(trimmed) do
          {:ok, _} -> :json
          {:error, _} -> :html
        end

      String.starts_with?(trimmed, "<") ->
        :html

      true ->
        # Default to HTML for ambiguous cases
        :html
    end
  end

  defp detect_response_type(_), do: :html
end
