defmodule Mydia.Settings.JsonListType do
  @moduledoc """
  Custom Ecto type for storing a list as JSON in a text column.

  This type allows storing lists in databases when using a text column instead of
  a native JSON/JSONB type. Works with both SQLite (which stores as text) and
  PostgreSQL (when the column is defined as text instead of jsonb).

  ## Usage
  In your schema:

      schema "my_table" do
        field :items, Mydia.Settings.JsonListType
      end

  When you load a record from the database, the field will automatically
  be a list instead of raw JSON text.
  """

  use Ecto.Type

  @doc """
  Returns the underlying database type (:string for text columns).
  """
  def type, do: :string

  @doc """
  Casts the given value to a list.

  Accepts:
  - List (returns as-is)
  - nil (returns empty list)
  """
  def cast(nil), do: {:ok, []}
  def cast(list) when is_list(list), do: {:ok, list}
  def cast(_), do: :error

  @doc """
  Loads data from the database (JSON string) and converts to a list.

  Handles backwards compatibility with old cookie storage format:
  - New format: JSON array of cookie objects
  - Old format: JSON object (converted to empty list)
  """
  def load(nil), do: {:ok, []}
  def load(""), do: {:ok, []}
  def load("[]"), do: {:ok, []}
  def load("{}"), do: {:ok, []}

  def load(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, list} when is_list(list) ->
        {:ok, list}

      {:ok, %{"cookies" => cookies}} when is_list(cookies) ->
        # Handle old wrapped format: {"cookies": [...]}
        {:ok, cookies}

      {:ok, map} when is_map(map) ->
        # Handle other old formats - return empty list for backwards compatibility
        # Old sessions will be re-created on next search
        {:ok, []}

      {:error, _} ->
        {:error, "Invalid JSON"}
    end
  end

  # Handle case where data is already a list (some adapters may do this)
  def load(list) when is_list(list), do: {:ok, list}

  # Handle case where data is already a map (backwards compatibility)
  def load(map) when is_map(map), do: {:ok, []}

  def load(_), do: :error

  @doc """
  Dumps a list to a JSON string for database storage.
  """
  def dump(nil), do: {:ok, "[]"}
  def dump(list) when list == [], do: {:ok, "[]"}

  def dump(list) when is_list(list) do
    {:ok, Jason.encode!(list)}
  end

  def dump(_), do: :error

  @doc """
  Compares two values for equality.
  """
  def equal?(list1, list2), do: list1 == list2

  @doc """
  Embeds the type as a parameter in queries.
  """
  def embed_as(_), do: :dump
end
