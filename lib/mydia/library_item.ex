defmodule Mydia.LibraryItem do
  @moduledoc """
  Behavior defining a common interface for library items.

  This behavior provides a unified API for displaying different types of
  library content (MediaItem for videos, Album for music, Book for books, etc.)
  in the library view components.

  Implementing modules must define functions for:
  - Getting display information (title, poster, metadata badges)
  - Getting navigation paths
  - Getting file-related information (size, counts)
  """

  @type item :: struct()
  @type badge :: %{label: String.t(), class: String.t()}

  @doc """
  Returns the display title for the item.
  """
  @callback display_title(item :: item()) :: String.t() | nil

  @doc """
  Returns the poster/cover image URL for the item.
  Returns a default placeholder if no image is available.
  """
  @callback poster_url(item :: item()) :: String.t()

  @doc """
  Returns the path to the item's detail page.
  """
  @callback item_path(item :: item()) :: String.t()

  @doc """
  Returns metadata badges to display on the item card.
  Each badge is a map with `:label` and optional `:class` keys.
  """
  @callback metadata_badges(item :: item()) :: [badge()]

  @doc """
  Returns the total file size in bytes for all files associated with the item.
  Returns 0 if no files are associated.
  """
  @callback file_size(item :: item()) :: non_neg_integer()

  @doc """
  Returns the year the item was released/published.
  """
  @callback year(item :: item()) :: integer() | nil

  @doc """
  Returns the item type as a string (e.g., "movie", "tv_show", "album", "book").
  """
  @callback item_type(item :: item()) :: String.t()

  @doc """
  Returns whether the item is being monitored for new content.
  """
  @callback monitored?(item :: item()) :: boolean()

  @doc """
  Returns the quality resolution badge (e.g., "720p", "1080p", "4K").
  Returns nil if no quality information is available.
  """
  @callback quality_badge(item :: item()) :: String.t() | nil

  @doc """
  Returns secondary text to display below the title (e.g., original title, artist name).
  """
  @callback secondary_text(item :: item()) :: String.t() | nil

  @doc """
  Returns a status tuple containing the status atom and additional counts/metadata.
  Used for displaying status indicators on cards.
  """
  @callback status(item :: item()) :: {atom(), map() | nil}

  @doc """
  Implementation helper - derives the module that implements LibraryItem for a given struct.
  """
  def impl_for(%module{} = _item) do
    case module do
      Mydia.Media.MediaItem -> Mydia.LibraryItem.MediaItem
      Mydia.Music.Album -> Mydia.LibraryItem.Album
      Mydia.Books.Book -> Mydia.LibraryItem.Book
      _ -> nil
    end
  end

  @doc """
  Calls the display_title callback for any library item.
  Returns nil if no implementation exists.
  """
  def display_title(item) do
    case impl_for(item) do
      nil -> nil
      impl -> apply(impl, :display_title, [item])
    end
  end

  @doc """
  Calls the poster_url callback for any library item.
  Returns a default placeholder if no implementation exists.
  """
  def poster_url(item) do
    case impl_for(item) do
      nil -> "/images/no-poster.svg"
      impl -> apply(impl, :poster_url, [item])
    end
  end

  @doc """
  Calls the item_path callback for any library item.
  Returns "#" if no implementation exists.
  """
  def item_path(item) do
    case impl_for(item) do
      nil -> "#"
      impl -> apply(impl, :item_path, [item])
    end
  end

  @doc """
  Calls the metadata_badges callback for any library item.
  Returns empty list if no implementation exists.
  """
  def metadata_badges(item) do
    case impl_for(item) do
      nil -> []
      impl -> apply(impl, :metadata_badges, [item])
    end
  end

  @doc """
  Calls the file_size callback for any library item.
  Returns 0 if no implementation exists.
  """
  def file_size(item) do
    case impl_for(item) do
      nil -> 0
      impl -> apply(impl, :file_size, [item])
    end
  end

  @doc """
  Calls the year callback for any library item.
  Returns nil if no implementation exists.
  """
  def year(item) do
    case impl_for(item) do
      nil -> nil
      impl -> apply(impl, :year, [item])
    end
  end

  @doc """
  Calls the item_type callback for any library item.
  Returns "unknown" if no implementation exists.
  """
  def item_type(item) do
    case impl_for(item) do
      nil -> "unknown"
      impl -> apply(impl, :item_type, [item])
    end
  end

  @doc """
  Calls the monitored? callback for any library item.
  Returns false if no implementation exists.
  """
  def monitored?(item) do
    case impl_for(item) do
      nil -> false
      impl -> apply(impl, :monitored?, [item])
    end
  end

  @doc """
  Calls the quality_badge callback for any library item.
  Returns nil if no implementation exists.
  """
  def quality_badge(item) do
    case impl_for(item) do
      nil -> nil
      impl -> apply(impl, :quality_badge, [item])
    end
  end

  @doc """
  Calls the secondary_text callback for any library item.
  Returns nil if no implementation exists.
  """
  def secondary_text(item) do
    case impl_for(item) do
      nil -> nil
      impl -> apply(impl, :secondary_text, [item])
    end
  end

  @doc """
  Calls the status callback for any library item.
  Returns {:unknown, nil} if no implementation exists.
  """
  def status(item) do
    case impl_for(item) do
      nil -> {:unknown, nil}
      impl -> apply(impl, :status, [item])
    end
  end
end
