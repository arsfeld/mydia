defmodule MydiaWeb.MediaLive.Show.Loaders do
  @moduledoc """
  Data loading functions for the MediaLive.Show page.
  Handles loading media items, downloads, timeline events, and related data.
  """

  alias Mydia.Media
  alias Mydia.Downloads
  alias Mydia.Events

  def load_media_item(id) do
    preload_list = build_preload_list()
    Media.get_media_item!(id, preload: preload_list)
  end

  defp build_preload_list do
    [
      quality_profile: [],
      episodes: [media_files: :library_path, downloads: :media_item],
      media_files: :library_path,
      downloads: []
    ]
  end

  def load_downloads_with_status(media_item) do
    # Get all downloads with real-time status from clients
    all_downloads = Downloads.list_downloads_with_status(filter: :all)

    # Filter to only downloads for this media item
    all_downloads
    |> Enum.filter(fn download_map ->
      download_map.media_item_id == media_item.id or
        (download_map.episode_id &&
           Enum.any?(media_item.episodes || [], fn ep -> ep.id == download_map.episode_id end))
    end)
  end

  def load_timeline_events(media_item) do
    # Get events from Events system for this media item
    events = Events.get_resource_events("media_item", media_item.id, limit: 50)

    # Format each event for timeline display
    events
    |> Enum.map(fn event ->
      formatted = Events.format_for_timeline(event)

      # Merge formatted properties with event data needed by template
      Map.merge(formatted, %{
        timestamp: event.inserted_at,
        metadata: MydiaWeb.MediaLive.Show.Formatters.format_metadata_for_display(event)
      })
    end)
  end

  # Load next episode to watch for TV shows
  def load_next_episode(media_item, socket) do
    if media_item.type == "tv_show" do
      user_id = socket.assigns.current_user.id

      case Mydia.Playback.get_next_episode(media_item.id, user_id) do
        {:continue, episode} -> {episode, :continue}
        {:next, episode} -> {episode, :next}
        {:start, episode} -> {episode, :start}
        :all_watched -> {nil, :all_watched}
        nil -> {nil, nil}
      end
    else
      {nil, nil}
    end
  end
end
