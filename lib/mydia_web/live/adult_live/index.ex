defmodule MydiaWeb.AdultLive.Index do
  @moduledoc """
  LiveView for browsing adult library content.

  Displays media files from adult library paths with thumbnail support,
  search, filtering, and sorting capabilities.
  """

  use MydiaWeb, :live_view

  alias Mydia.Jobs.ThumbnailGeneration
  alias Mydia.Library
  alias Mydia.Library.GeneratedMedia

  @items_per_page 50
  @items_per_scroll 25

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ThumbnailGeneration.subscribe()
    end

    {:ok,
     socket
     |> assign(:view_mode, :grid)
     |> assign(:search_query, "")
     |> assign(:sort_by, "added_desc")
     |> assign(:page, 0)
     |> assign(:has_more, true)
     |> assign(:page_title, "Adult")
     |> assign(:generating_thumbnails, false)
     |> assign(:generation_progress, nil)
     |> stream(:files, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, load_files(socket, reset: true)}
  end

  @impl true
  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    view_mode = String.to_existing_atom(mode)

    {:noreply,
     socket
     |> assign(:view_mode, view_mode)
     |> assign(:page, 0)
     |> load_files(reset: true)}
  end

  def handle_event("search", params, socket) do
    query = params["search"] || params["value"] || ""

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 0)
     |> load_files(reset: true)}
  end

  def handle_event("filter", params, socket) do
    sort_by = params["sort_by"] || socket.assigns.sort_by

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:page, 0)
     |> load_files(reset: true)}
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.has_more do
      {:noreply,
       socket
       |> update(:page, &(&1 + 1))
       |> load_files(reset: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("generate_all_thumbnails", _params, socket) do
    case ThumbnailGeneration.enqueue_missing(library_type: :adult) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> assign(:generating_thumbnails, true)
         |> put_flash(:info, "Thumbnail generation started")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start generation: #{inspect(reason)}")}
    end
  end

  def handle_event("generate_all_sprites", _params, socket) do
    case ThumbnailGeneration.enqueue_missing(library_type: :adult, include_sprites: true) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> assign(:generating_thumbnails, true)
         |> put_flash(:info, "Thumbnail and sprite generation started")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start generation: #{inspect(reason)}")}
    end
  end

  def handle_event("cancel_generation", _params, socket) do
    ThumbnailGeneration.cancel_all()

    {:noreply,
     socket
     |> assign(:generating_thumbnails, false)
     |> assign(:generation_progress, nil)
     |> put_flash(:info, "Generation cancelled")}
  end

  @impl true
  def handle_info({:thumbnail_generation, %{event: :started} = progress}, socket) do
    {:noreply,
     socket
     |> assign(:generating_thumbnails, true)
     |> assign(:generation_progress, progress)}
  end

  def handle_info({:thumbnail_generation, %{event: :progress} = progress}, socket) do
    {:noreply, assign(socket, :generation_progress, progress)}
  end

  def handle_info({:thumbnail_generation, %{event: :completed} = progress}, socket) do
    {:noreply,
     socket
     |> assign(:generating_thumbnails, false)
     |> assign(:generation_progress, progress)
     |> load_files(reset: true)
     |> put_flash(:info, "Generation complete: #{progress.completed}/#{progress.total} succeeded")}
  end

  def handle_info({:thumbnail_generation, %{event: :cancelled}}, socket) do
    {:noreply,
     socket
     |> assign(:generating_thumbnails, false)
     |> assign(:generation_progress, nil)}
  end

  defp load_files(socket, opts) do
    reset? = Keyword.get(opts, :reset, false)
    page = if reset?, do: 0, else: socket.assigns.page
    offset = if page == 0, do: 0, else: @items_per_page + (page - 1) * @items_per_scroll
    limit = if page == 0, do: @items_per_page, else: @items_per_scroll

    # Get all media files from adult library paths
    all_files =
      Library.list_media_files(
        library_path_type: :adult,
        preload: [:library_path]
      )

    # Apply search filter
    files =
      if socket.assigns.search_query != "" do
        query = String.downcase(socket.assigns.search_query)

        Enum.filter(all_files, fn file ->
          filename = file.relative_path || ""
          String.contains?(String.downcase(filename), query)
        end)
      else
        all_files
      end

    # Apply sorting
    files = apply_sorting(files, socket.assigns.sort_by)

    # Apply pagination
    paginated_files = files |> Enum.drop(offset) |> Enum.take(limit)
    has_more = length(files) > offset + limit

    socket =
      socket
      |> assign(:has_more, has_more)
      |> assign(:files_empty?, reset? and files == [])

    if reset? do
      stream(socket, :files, paginated_files, reset: true)
    else
      stream(socket, :files, paginated_files)
    end
  end

  defp apply_sorting(files, sort_by) do
    case sort_by do
      "name_asc" ->
        Enum.sort_by(files, &get_filename(&1), :asc)

      "name_desc" ->
        Enum.sort_by(files, &get_filename(&1), :desc)

      "size_asc" ->
        Enum.sort_by(files, & &1.size, :asc)

      "size_desc" ->
        Enum.sort_by(files, & &1.size, :desc)

      "added_asc" ->
        Enum.sort_by(files, & &1.inserted_at, :asc)

      "added_desc" ->
        Enum.sort_by(files, & &1.inserted_at, :desc)

      _ ->
        Enum.sort_by(files, & &1.inserted_at, :desc)
    end
  end

  defp get_filename(file) do
    case file.relative_path do
      nil -> ""
      path -> Path.basename(path) |> String.downcase()
    end
  end

  defp get_display_name(file) do
    case file.relative_path do
      nil -> "Unknown"
      path -> Path.basename(path)
    end
  end

  defp get_thumbnail_url(file) do
    if file.cover_blob do
      GeneratedMedia.url_path(:cover, file.cover_blob)
    else
      "/images/no-poster.svg"
    end
  end

  defp get_sprite_url(file) do
    if file.sprite_blob do
      GeneratedMedia.url_path(:sprite, file.sprite_blob)
    else
      nil
    end
  end

  defp get_duration(file) do
    case file.metadata do
      %{"duration" => duration} when is_number(duration) -> trunc(duration)
      _ -> nil
    end
  end

  defp format_file_size(nil), do: "-"

  defp format_file_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 0)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_resolution(nil), do: nil
  defp format_resolution(""), do: nil
  defp format_resolution(resolution), do: resolution

  defp format_date(nil), do: "-"

  defp format_date(%DateTime{} = date) do
    Calendar.strftime(date, "%Y-%m-%d")
  end
end
