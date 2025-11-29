defmodule MydiaWeb.ActivityLive.Index do
  use MydiaWeb, :live_view
  alias Mydia.Events
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        # Subscribe to events for real-time updates
        PubSub.subscribe(Mydia.PubSub, "events:all")

        socket
        |> assign(:category_filter, "all")
        |> assign(:events_empty?, false)
        |> load_events()
      else
        socket
        |> assign(:category_filter, "all")
        |> assign(:events_empty?, true)
        |> stream(:events, [])
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Activity")}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    {:noreply,
     socket
     |> assign(:category_filter, category)
     |> load_events()}
  end

  @impl true
  def handle_info({:event_created, event}, socket) do
    # Only add event if it matches current filter
    should_add =
      socket.assigns.category_filter == "all" ||
        event.category == socket.assigns.category_filter

    socket =
      if should_add do
        socket
        |> assign(:events_empty?, false)
        |> stream_insert(:events, event, at: 0)
      else
        socket
      end

    {:noreply, socket}
  end

  ## Private Helpers

  defp load_events(socket) do
    category = socket.assigns.category_filter

    filter_opts =
      if category == "all" do
        []
      else
        [category: category]
      end

    events = Events.list_events(filter_opts ++ [limit: 50])

    socket
    |> assign(:events_empty?, events == [])
    |> stream(:events, events, reset: true)
  end

  ## UI Helpers

  defp format_event_description(event) do
    case event.type do
      "media_item.added" ->
        title = event.metadata["title"] || "Unknown"
        media_type = event.metadata["media_type"]
        type_label = if media_type == "movie", do: "movie", else: "TV show"
        "Added #{type_label}: #{title}"

      "media_item.updated" ->
        title = event.metadata["title"] || "Unknown"
        reason = event.metadata["reason"] || "Updated"
        "#{reason}: #{title}"

      "media_item.removed" ->
        title = event.metadata["title"] || "Unknown"
        "Removed: #{title}"

      "media_item.monitoring_changed" ->
        title = event.metadata["title"] || "Unknown"
        monitored = event.metadata["monitored"]
        action = if monitored, do: "Started monitoring", else: "Stopped monitoring"
        "#{action}: #{title}"

      "download.initiated" ->
        title = event.metadata["title"] || "Unknown"
        "Started download: #{title}"

      "download.completed" ->
        title = event.metadata["title"] || "Unknown"
        "Download completed: #{title}"

      "download.failed" ->
        title = event.metadata["title"] || "Unknown"
        error = event.metadata["error_message"] || "Unknown error"
        "Download failed: #{title} (#{error})"

      "download.cancelled" ->
        title = event.metadata["title"] || "Unknown"
        "Download cancelled: #{title}"

      "download.paused" ->
        title = event.metadata["title"] || "Unknown"
        "Download paused: #{title}"

      "download.resumed" ->
        title = event.metadata["title"] || "Unknown"
        "Download resumed: #{title}"

      "job.executed" ->
        job_name = event.metadata["job_name"] || "Unknown"
        "Job executed: #{job_name}"

      "job.failed" ->
        job_name = event.metadata["job_name"] || "Unknown"
        error = event.metadata["error_message"] || "Unknown error"
        "Job failed: #{job_name} (#{error})"

      _ ->
        event.type
    end
  end

  defp format_actor(event) do
    case event.actor_type do
      :user -> "User"
      :system -> "System"
      :job -> event.actor_id || "Job"
      nil -> "System"
      _ -> "Unknown"
    end
  end

  defp event_icon(event) do
    case event.type do
      "media_item.added" -> "hero-plus-circle"
      "media_item.updated" -> "hero-arrow-path"
      "media_item.removed" -> "hero-trash"
      "media_item.monitoring_changed" -> "hero-eye"
      "download.initiated" -> "hero-arrow-down-tray"
      "download.completed" -> "hero-check-circle"
      "download.failed" -> "hero-x-circle"
      "download.cancelled" -> "hero-x-mark"
      "download.paused" -> "hero-pause"
      "download.resumed" -> "hero-play"
      "job.executed" -> "hero-cog-6-tooth"
      "job.failed" -> "hero-exclamation-triangle"
      _ -> "hero-information-circle"
    end
  end

  defp severity_badge_class(severity) do
    case severity do
      :error -> "badge-error"
      :warning -> "badge-warning"
      :info -> "badge-info"
      _ -> "badge-ghost"
    end
  end

  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604_800 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  defp category_name(category) do
    case category do
      "media" -> "Media"
      "downloads" -> "Downloads"
      "library" -> "Library"
      "system" -> "System"
      "auth" -> "Authentication"
      "all" -> "All"
      _ -> String.capitalize(category)
    end
  end
end
