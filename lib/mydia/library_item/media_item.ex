defmodule Mydia.LibraryItem.MediaItem do
  @moduledoc """
  LibraryItem implementation for MediaItem (movies and TV shows).
  """
  @behaviour Mydia.LibraryItem

  alias Mydia.Media
  alias Mydia.Metadata.Structs.MediaMetadata

  @default_poster "/images/no-poster.svg"

  @impl Mydia.LibraryItem
  def display_title(%Mydia.Media.MediaItem{title: title}), do: title

  @impl Mydia.LibraryItem
  def poster_url(%Mydia.Media.MediaItem{metadata: metadata}) do
    case metadata do
      %MediaMetadata{poster_path: path} when is_binary(path) ->
        "https://image.tmdb.org/t/p/w500#{path}"

      _ ->
        @default_poster
    end
  end

  @impl Mydia.LibraryItem
  def item_path(%Mydia.Media.MediaItem{id: id}) do
    "/media/#{id}"
  end

  @impl Mydia.LibraryItem
  def metadata_badges(%Mydia.Media.MediaItem{} = item) do
    badges = []

    # Add quality badge if available
    badges =
      case quality_badge(item) do
        nil -> badges
        quality -> [%{label: quality, class: "badge-primary"} | badges]
      end

    # Add type badge
    type_badge =
      case item.type do
        "movie" -> %{label: "Movie", class: "badge-info"}
        "tv_show" -> %{label: "TV Show", class: "badge-secondary"}
        _ -> nil
      end

    if type_badge, do: [type_badge | badges], else: badges
  end

  @impl Mydia.LibraryItem
  def file_size(%Mydia.Media.MediaItem{media_files: media_files})
      when is_list(media_files) do
    media_files
    |> Enum.map(& &1.size)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  def file_size(_), do: 0

  @impl Mydia.LibraryItem
  def year(%Mydia.Media.MediaItem{year: year}), do: year

  @impl Mydia.LibraryItem
  def item_type(%Mydia.Media.MediaItem{type: type}), do: type

  @impl Mydia.LibraryItem
  def monitored?(%Mydia.Media.MediaItem{monitored: monitored}), do: monitored

  @impl Mydia.LibraryItem
  def quality_badge(%Mydia.Media.MediaItem{media_files: media_files})
      when is_list(media_files) do
    media_files
    |> Enum.map(& &1.resolution)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort(:desc)
    |> List.first()
  end

  def quality_badge(_), do: nil

  @impl Mydia.LibraryItem
  def secondary_text(%Mydia.Media.MediaItem{original_title: original_title, title: title}) do
    if original_title && original_title != title do
      original_title
    else
      nil
    end
  end

  @impl Mydia.LibraryItem
  def status(%Mydia.Media.MediaItem{} = item) do
    Media.get_media_status(item)
  end
end
