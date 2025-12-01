defmodule MydiaWeb.Live.UserAuth do
  @moduledoc """
  LiveView authentication hooks.

  Provides `on_mount` hooks for LiveViews to authenticate users
  and assign current_user to the socket.
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias Mydia.Accounts
  alias Mydia.Accounts.Authorization
  alias Mydia.Auth.Guardian
  alias Mydia.MediaRequests

  @doc """
  LiveView mount hook for authentication and authorization.

  Supports multiple modes:
  - `:ensure_authenticated` - Requires user to be logged in
  - `:maybe_authenticated` - Loads user if present, but doesn't require it
  - `{:ensure_role, role}` - Requires user to have a specific role
  - `:load_navigation_data` - Loads counts for navigation sidebar/layout

  Usage in LiveView:
      on_mount {MydiaWeb.Live.UserAuth, :ensure_authenticated}
      on_mount {MydiaWeb.Live.UserAuth, :maybe_authenticated}
      on_mount {MydiaWeb.Live.UserAuth, {:ensure_role, :admin}}
      on_mount {MydiaWeb.Live.UserAuth, :load_navigation_data}
  """
  def on_mount(mode, params, session, socket)

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    case socket.assigns do
      %{current_user: %Mydia.Accounts.User{}} ->
        {:cont, socket}

      _ ->
        socket =
          socket
          |> put_flash(:error, "You must be logged in to access this page")
          |> redirect(to: "/auth/login")

        {:halt, socket}
    end
  end

  def on_mount(:maybe_authenticated, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount({:ensure_role, required_role}, _params, session, socket) do
    socket = mount_current_user(socket, session)

    case socket.assigns do
      %{current_user: %Mydia.Accounts.User{} = user} ->
        if has_role?(user, required_role) do
          {:cont, socket}
        else
          socket =
            socket
            |> put_flash(:error, "You do not have permission to access this page")
            |> redirect(to: "/")

          {:halt, socket}
        end

      _ ->
        socket =
          socket
          |> put_flash(:error, "You do not have permission to access this page")
          |> redirect(to: "/")

        {:halt, socket}
    end
  end

  def on_mount(:load_navigation_data, _params, _session, socket) do
    # Subscribe to job status updates for real-time sidebar indicator
    if connected?(socket) do
      Mydia.Jobs.Broadcaster.subscribe()
    end

    # Load navigation counts once per LiveView mount
    # These are used by the layout component for sidebar badges
    pending_requests_count =
      case Map.fetch(socket.assigns, :current_user) do
        {:ok, user} when not is_nil(user) ->
          if Authorization.can_manage_requests?(user) do
            MediaRequests.count_pending_requests()
          else
            0
          end

        _ ->
          0
      end

    # Get configured library types (for showing/hiding sidebar links)
    configured_library_types = get_configured_library_types()

    # Get adult content count only if adult library is configured
    adult_count =
      if MapSet.member?(configured_library_types, :adult) do
        Mydia.Media.count_by_library_path_type(:adult)
      else
        0
      end

    # Get music album count only if music library is configured
    music_count =
      if MapSet.member?(configured_library_types, :music) do
        Mydia.Music.count_albums()
      else
        0
      end

    # Get books count only if books library is configured
    books_count =
      if MapSet.member?(configured_library_types, :books) do
        Mydia.Books.count_books()
      else
        0
      end

    # Get executing jobs for sidebar status indicator
    executing_jobs = Mydia.Jobs.list_executing_jobs()

    socket =
      socket
      |> assign(:movie_count, Mydia.Media.count_movies())
      |> assign(:tv_show_count, Mydia.Media.count_tv_shows())
      |> assign(:downloads_count, Mydia.Downloads.count_active_downloads())
      |> assign(:pending_requests_count, pending_requests_count)
      |> assign(:configured_library_types, configured_library_types)
      |> assign(:adult_count, adult_count)
      |> assign(:music_count, music_count)
      |> assign(:books_count, books_count)
      |> assign(:executing_jobs, executing_jobs)
      |> attach_hook(:jobs_status_hook, :handle_info, &handle_jobs_status/2)

    {:cont, socket}
  end

  # Handle job status updates from PubSub
  defp handle_jobs_status({:jobs_status_changed, executing_jobs}, socket) do
    {:halt, assign(socket, :executing_jobs, executing_jobs)}
  end

  defp handle_jobs_status(_msg, socket) do
    {:cont, socket}
  end

  # Get a MapSet of library types that have at least one enabled library path
  defp get_configured_library_types do
    Mydia.Settings.list_library_paths()
    |> Enum.reject(& &1.disabled)
    |> Enum.map(& &1.type)
    |> MapSet.new()
  end

  # Mount the current user from the session
  defp mount_current_user(socket, session) do
    case session do
      %{"guardian_default_token" => token} ->
        case Guardian.verify_token(token) do
          {:ok, user} ->
            assign(socket, current_user: user)

          {:error, _reason} ->
            assign(socket, current_user: nil)
        end

      %{"guardian_token" => token} ->
        # Legacy key for backward compatibility
        case Guardian.verify_token(token) do
          {:ok, user} ->
            assign(socket, current_user: user)

          {:error, _reason} ->
            assign(socket, current_user: nil)
        end

      %{"user_id" => user_id} ->
        # Fallback: load user by ID if no Guardian token
        case Accounts.get_user!(user_id) do
          user -> assign(socket, current_user: user)
        end

      _ ->
        assign(socket, current_user: nil)
    end
  rescue
    Ecto.NoResultsError ->
      assign(socket, current_user: nil)
  end

  # Check if user has the required role
  defp has_role?(user, required_role) do
    role_hierarchy = %{
      "admin" => 4,
      "user" => 3,
      "readonly" => 2,
      "guest" => 1
    }

    user_level = Map.get(role_hierarchy, user.role, 0)
    required_level = Map.get(role_hierarchy, to_string(required_role), 999)

    user_level >= required_level
  end
end
