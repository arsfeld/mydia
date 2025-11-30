defmodule MydiaWeb.DashboardLive.Index do
  use MydiaWeb, :live_view
  alias Mydia.Media
  alias Mydia.Library
  alias Mydia.Downloads
  alias Mydia.Metadata
  alias Mydia.MediaRequests
  alias Mydia.Accounts.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Mydia.PubSub, "downloads")

        socket
        |> assign(:trending_movies_loading, true)
        |> assign(:trending_tv_loading, true)
        |> assign(:trending_movies, [])
        |> assign(:trending_tv, [])
        |> assign(:library_status_map, %{})
        |> assign(:adding_item_id, nil)
        |> load_dashboard_data()
      else
        socket
        |> assign(:trending_movies_loading, false)
        |> assign(:trending_tv_loading, false)
        |> assign(:trending_movies, [])
        |> assign(:trending_tv, [])
        |> assign(:movie_count, 0)
        |> assign(:tv_show_count, 0)
        |> assign(:active_downloads_count, 0)
        |> assign(:total_storage, "0 GB")
        |> assign(:recent_episodes, [])
        |> assign(:upcoming_episodes, [])
        |> assign(:library_status_map, %{})
        |> assign(:adding_item_id, nil)
        |> assign(:pending_requests_count, 0)
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Dashboard")}
  end

  defp load_dashboard_data(socket) do
    # Load basic stats
    movie_count = Media.count_movies()
    tv_show_count = Media.count_tv_shows()
    active_downloads_count = Downloads.count_active_downloads()
    total_storage = Library.total_storage_bytes() |> format_bytes()

    # Load library status map for efficient lookups
    library_status_map = Media.get_library_status_map()

    # Load recent and upcoming content for monitored media
    today = Date.utc_today()
    seven_days_ago = Date.add(today, -7)
    seven_days_ahead = Date.add(today, 7)

    recent_episodes = Media.list_episodes_by_air_date(seven_days_ago, today, monitored: true)
    upcoming_episodes = Media.list_episodes_by_air_date(today, seven_days_ahead, monitored: true)

    # Load pending requests count for admins
    pending_requests_count =
      if Authorization.can_manage_requests?(socket.assigns.current_user) do
        MediaRequests.count_pending_requests()
      else
        0
      end

    # Load trending data asynchronously
    send(self(), :load_trending_movies)
    send(self(), :load_trending_tv)

    socket
    |> assign(:movie_count, movie_count)
    |> assign(:tv_show_count, tv_show_count)
    |> assign(:active_downloads_count, active_downloads_count)
    |> assign(:total_storage, total_storage)
    |> assign(:library_status_map, library_status_map)
    |> assign(:recent_episodes, Enum.take(recent_episodes, 10))
    |> assign(:upcoming_episodes, Enum.take(upcoming_episodes, 10))
    |> assign(:pending_requests_count, pending_requests_count)
  end

  @impl true
  def handle_event("add_to_library", %{"tmdb_id" => tmdb_id, "media_type" => media_type}, socket) do
    media_type_atom = String.to_existing_atom(media_type)

    # Set the adding state
    socket = assign(socket, :adding_item_id, tmdb_id)

    # Start async task to add media
    send(self(), {:add_media_to_library, tmdb_id, media_type_atom})

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_trending_movies, socket) do
    case Metadata.trending_movies() do
      {:ok, movies} ->
        enriched_movies =
          movies
          |> Enum.take(10)
          |> enrich_with_library_status(socket.assigns.library_status_map)

        {:noreply,
         socket
         |> assign(:trending_movies, enriched_movies)
         |> assign(:trending_movies_loading, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:trending_movies, [])
         |> assign(:trending_movies_loading, false)}
    end
  end

  def handle_info(:load_trending_tv, socket) do
    case Metadata.trending_tv_shows() do
      {:ok, shows} ->
        enriched_shows =
          shows
          |> Enum.take(10)
          |> enrich_with_library_status(socket.assigns.library_status_map)

        {:noreply,
         socket
         |> assign(:trending_tv, enriched_shows)
         |> assign(:trending_tv_loading, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:trending_tv, [])
         |> assign(:trending_tv_loading, false)}
    end
  end

  def handle_info({:download_updated, _download_id}, socket) do
    # Just trigger a re-render to update the downloads counter in the sidebar
    # The counter will be recalculated when the layout renders
    {:noreply, socket}
  end

  def handle_info({:add_media_to_library, tmdb_id, media_type}, socket) do
    # Convert tmdb_id to integer for consistent map key type
    tmdb_id_int =
      case tmdb_id do
        id when is_integer(id) -> id
        id when is_binary(id) -> String.to_integer(id)
      end

    config = Metadata.default_relay_config()

    case Metadata.fetch_by_id(config, tmdb_id, media_type: media_type) do
      {:ok, metadata} ->
        attrs = build_media_item_attrs(metadata, media_type)

        case Media.create_media_item(attrs) do
          {:ok, media_item} ->
            # Create episodes for TV shows if monitored
            if media_type == :tv_show and media_item.monitored do
              create_episodes_for_media(media_item, metadata)
            end

            # Update library status map with integer key
            library_status_map =
              Map.put(socket.assigns.library_status_map, tmdb_id_int, %{
                in_library: true,
                monitored: media_item.monitored,
                type: if(media_type == :movie, do: "movie", else: "tv_show"),
                id: media_item.id
              })

            # Re-enrich trending items with updated library status
            trending_movies =
              enrich_with_library_status(socket.assigns.trending_movies, library_status_map)

            trending_tv =
              enrich_with_library_status(socket.assigns.trending_tv, library_status_map)

            {:noreply,
             socket
             |> assign(:adding_item_id, nil)
             |> assign(:library_status_map, library_status_map)
             |> assign(:trending_movies, trending_movies)
             |> assign(:trending_tv, trending_tv)
             |> put_flash(:info, "#{media_item.title} has been added to your library")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(:adding_item_id, nil)
             |> put_flash(:error, "Failed to add: #{format_changeset_errors(changeset)}")}
        end

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:adding_item_id, nil)
         |> put_flash(:error, "Failed to fetch metadata: #{inspect(reason)}")}
    end
  end

  ## Private Helpers

  defp enrich_with_library_status(items, library_status_map) do
    Enum.map(items, fn item ->
      # Convert provider_id to integer for map lookup
      tmdb_id =
        case item.provider_id do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          nil -> nil
        end

      library_status = Map.get(library_status_map, tmdb_id, %{in_library: false})

      Map.merge(item, %{
        in_library: library_status[:in_library] || false,
        monitored: library_status[:monitored] || false,
        id: library_status[:id]
      })
    end)
  end

  defp build_media_item_attrs(metadata, media_type) do
    type_string = if media_type == :movie, do: "movie", else: "tv_show"

    # Extract provider_id and convert to integer for tmdb_id
    tmdb_id =
      case metadata.provider_id do
        nil -> nil
        id when is_integer(id) -> id
        id when is_binary(id) -> String.to_integer(id)
      end

    %{
      type: type_string,
      title: metadata.title,
      original_title: metadata.original_title,
      year: extract_year(metadata),
      tmdb_id: tmdb_id,
      imdb_id: metadata.imdb_id,
      metadata: metadata,
      monitored: true
    }
  end

  defp extract_year(metadata) do
    cond do
      metadata.year ->
        metadata.year

      metadata.release_date || metadata.first_air_date ->
        date_value = metadata.release_date || metadata.first_air_date
        extract_year_from_date(date_value)

      true ->
        nil
    end
  end

  defp extract_year_from_date(%Date{} = date), do: date.year

  defp extract_year_from_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date.year
      _ -> nil
    end
  end

  defp extract_year_from_date(_), do: nil

  defp create_episodes_for_media(media_item, metadata) do
    # Get seasons from metadata
    seasons = metadata.seasons || []

    # Create episodes for all seasons
    Enum.each(seasons, fn season ->
      create_season_episodes(media_item, season)
    end)
  end

  defp create_season_episodes(media_item, season) do
    config = Metadata.default_relay_config()

    case Metadata.fetch_season(
           config,
           to_string(media_item.tmdb_id),
           season[:season_number]
         ) do
      {:ok, season_data} ->
        episodes = season_data.episodes || []

        Enum.each(episodes, fn episode ->
          Media.create_episode(%{
            media_item_id: media_item.id,
            season_number: episode.season_number,
            episode_number: episode.episode_number,
            title: episode.name,
            air_date: parse_air_date(episode.air_date),
            metadata: episode,
            monitored: true
          })
        end)

      {:error, _reason} ->
        :ok
    end
  end

  defp parse_air_date(nil), do: nil
  defp parse_air_date(%Date{} = date), do: date

  defp parse_air_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_air_date(_), do: nil

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"

  defp format_bytes(bytes) when bytes < 1024 * 1024 do
    kb = bytes / 1024
    "#{Float.round(kb, 1)} KB"
  end

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024 do
    mb = bytes / (1024 * 1024)
    "#{Float.round(mb, 1)} MB"
  end

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024 * 1024 do
    gb = bytes / (1024 * 1024 * 1024)
    "#{Float.round(gb, 1)} GB"
  end

  defp format_bytes(bytes) do
    tb = bytes / (1024 * 1024 * 1024 * 1024)
    "#{Float.round(tb, 2)} TB"
  end
end
