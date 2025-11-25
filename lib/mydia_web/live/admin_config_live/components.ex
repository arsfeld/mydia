defmodule MydiaWeb.AdminConfigLive.Components do
  @moduledoc """
  Function components for the admin configuration LiveView.

  This module contains all the tab and modal components extracted
  from the main template for improved maintainability.
  """
  use MydiaWeb, :html

  alias Mydia.Settings

  # ============================================================================
  # Tab Components
  # ============================================================================

  @doc """
  Renders the System Status tab content.
  """
  attr :system_info, :map, required: true
  attr :database_info, :map, required: true
  attr :library_paths, :list, required: true
  attr :download_clients, :list, required: true
  attr :indexers, :list, required: true

  def status_tab(assigns) do
    ~H"""
    <div class="space-y-6 sm:space-y-8 p-4 sm:p-6">
      <%!-- Top Row: System Info + Database --%>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8">
        <%!-- System Information --%>
        <div>
          <h3 class="text-lg font-semibold flex items-center gap-2 mb-3 sm:mb-4">
            <.icon name="hero-server" class="w-5 h-5 text-primary" /> System
          </h3>
          <div class="grid grid-cols-2 gap-2 sm:gap-4">
            <div class="stat p-3 sm:p-4 bg-base-200 rounded-lg">
              <div class="stat-title text-xs sm:text-sm">Version</div>
              <div class="stat-value text-base sm:text-xl">
                {@system_info.app_version}
                <%= if @system_info.dev_mode do %>
                  <span class="badge badge-warning badge-xs sm:badge-sm ml-1">dev</span>
                <% end %>
              </div>
            </div>
            <div class="stat p-3 sm:p-4 bg-base-200 rounded-lg">
              <div class="stat-title text-xs sm:text-sm">Elixir</div>
              <div class="stat-value text-base sm:text-xl">{@system_info.elixir_version}</div>
            </div>
            <div class="stat p-3 sm:p-4 bg-base-200 rounded-lg">
              <div class="stat-title text-xs sm:text-sm">Memory</div>
              <div class="stat-value text-base sm:text-xl">{@system_info.memory_used}</div>
            </div>
            <div class="stat p-3 sm:p-4 bg-base-200 rounded-lg">
              <div class="stat-title text-xs sm:text-sm">Uptime</div>
              <div class="stat-value text-base sm:text-xl">{@system_info.uptime}</div>
            </div>
          </div>
        </div>

        <%!-- Database Information --%>
        <div>
          <h3 class="text-lg font-semibold flex items-center gap-2 mb-3 sm:mb-4 flex-wrap">
            <.icon name="hero-circle-stack" class="w-5 h-5 text-primary" /> Database
            <span class={"badge badge-sm sm:badge-md #{health_badge(@database_info.health)}"}>
              {if @database_info.health == :healthy, do: "Healthy", else: "Unhealthy"}
            </span>
          </h3>
          <div class="space-y-2 sm:space-y-3 bg-base-200 rounded-lg p-3 sm:p-5">
            <%= if @database_info.adapter == :postgres do %>
              <div class="flex justify-between items-center gap-2">
                <span class="text-base-content/70 text-sm">Adapter</span>
                <span class="badge badge-info badge-sm">PostgreSQL</span>
              </div>
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-1 sm:gap-2">
                <span class="text-base-content/70 text-sm">Host</span>
                <code class="text-xs sm:text-sm bg-base-300 px-2 py-1 rounded truncate">
                  {@database_info.hostname}:{@database_info.port}
                </code>
              </div>
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-1 sm:gap-2">
                <span class="text-base-content/70 text-sm">Database</span>
                <code class="text-xs sm:text-sm bg-base-300 px-2 py-1 rounded truncate">
                  {@database_info.database}
                </code>
              </div>
              <div class="flex justify-between items-center gap-2">
                <span class="text-base-content/70 text-sm">Size</span>
                <span class="font-medium text-sm">{@database_info.size}</span>
              </div>
            <% else %>
              <div class="flex justify-between items-center gap-2">
                <span class="text-base-content/70 text-sm">Adapter</span>
                <span class="badge badge-info badge-sm">SQLite</span>
              </div>
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-1 sm:gap-2">
                <span class="text-base-content/70 text-sm">Location</span>
                <code class="text-xs sm:text-sm bg-base-300 px-2 py-1 rounded truncate max-w-full sm:max-w-[250px]">
                  {@database_info.path}
                </code>
              </div>
              <div class="flex justify-between items-center gap-2">
                <span class="text-base-content/70 text-sm">Size</span>
                <span class="font-medium text-sm">{@database_info.size}</span>
              </div>
              <div class="flex justify-between items-center gap-2">
                <span class="text-base-content/70 text-sm">Exists</span>
                <span class={[
                  "badge badge-sm",
                  if(@database_info.exists, do: "badge-success", else: "badge-error")
                ]}>
                  {if @database_info.exists, do: "Yes", else: "No"}
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div class="divider"></div>

      <%!-- Bottom Row: Summary Tables in Grid --%>
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 sm:gap-8">
        <%!-- Library Paths Summary --%>
        <div>
          <h3 class="text-lg font-semibold flex items-center gap-2 mb-4">
            <.icon name="hero-folder" class="w-5 h-5 text-primary" /> Library Paths
            <span class="badge badge-ghost">{length(@library_paths)}</span>
          </h3>
          <%= if @library_paths == [] do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>No paths configured</span>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Path</th>
                    <th>Type</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for path <- @library_paths do %>
                    <tr>
                      <td class="font-mono text-sm truncate max-w-[180px]" title={path.path}>
                        {path.path}
                      </td>
                      <td><span class="badge badge-sm">{path.type}</span></td>
                      <td>
                        <span class={[
                          "badge badge-sm",
                          if(path.monitored, do: "badge-success", else: "badge-ghost")
                        ]}>
                          {if path.monitored, do: "Active", else: "Off"}
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>

        <%!-- Download Clients Summary --%>
        <div>
          <h3 class="text-lg font-semibold flex items-center gap-2 mb-4">
            <.icon name="hero-arrow-down-tray" class="w-5 h-5 text-primary" /> Clients
            <span class="badge badge-ghost">{length(@download_clients)}</span>
          </h3>
          <%= if @download_clients == [] do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>No clients configured</span>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for client <- @download_clients do %>
                    <tr>
                      <td class="font-medium">{client.name}</td>
                      <td><span class="badge badge-sm">{client.type}</span></td>
                      <td>
                        <span class={[
                          "badge badge-sm",
                          if(client.enabled, do: "badge-success", else: "badge-ghost")
                        ]}>
                          {if client.enabled, do: "On", else: "Off"}
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>

        <%!-- Indexers Summary --%>
        <div>
          <h3 class="text-lg font-semibold flex items-center gap-2 mb-4">
            <.icon name="hero-magnifying-glass" class="w-5 h-5 text-primary" /> Indexers
            <span class="badge badge-ghost">{length(@indexers)}</span>
          </h3>
          <%= if @indexers == [] do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>No indexers configured</span>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for indexer <- @indexers do %>
                    <tr>
                      <td class="font-medium">{indexer.name}</td>
                      <td>
                        <span class="badge badge-sm">
                          {format_indexer_type(indexer.type)}
                        </span>
                      </td>
                      <td>
                        <span class={[
                          "badge badge-sm",
                          if(indexer.enabled, do: "badge-success", else: "badge-ghost")
                        ]}>
                          {if indexer.enabled, do: "On", else: "Off"}
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the General Settings tab content.
  """
  attr :config_settings_with_sources, :map, required: true
  attr :crash_report_stats, :map, required: true

  def general_settings_tab(assigns) do
    ~H"""
    <div class="p-4 sm:p-6 space-y-6 sm:space-y-8">
      <%!-- Crash Reporting Stats --%>
      <%= if @crash_report_stats.enabled do %>
        <div class="stats stats-vertical sm:stats-horizontal shadow bg-base-200 w-full">
          <div class="stat">
            <div class="stat-figure text-warning">
              <.icon name="hero-bug-ant" class="w-8 h-8" />
            </div>
            <div class="stat-title">Crash Reports</div>
            <div class="stat-value text-warning">{@crash_report_stats.queued_reports}</div>
            <div class="stat-desc">Queued for sending</div>
          </div>
          <div class="stat">
            <div class="stat-figure text-success">
              <.icon name="hero-check-circle" class="w-8 h-8" />
            </div>
            <div class="stat-title">Sent</div>
            <div class="stat-value text-success">
              {Map.get(@crash_report_stats, :sent_reports, 0)}
            </div>
            <div class="stat-desc">Successfully reported</div>
          </div>
          <%= if @crash_report_stats.queued_reports > 0 do %>
            <div class="stat">
              <div class="stat-figure">
                <button
                  class="btn btn-warning btn-outline btn-sm"
                  phx-click="clear_crash_queue"
                  data-confirm="Clear all pending crash reports?"
                >
                  <.icon name="hero-trash" class="w-4 h-4" /> Clear
                </button>
              </div>
              <div class="stat-title">Actions</div>
              <div class="stat-desc">Clear pending reports</div>
            </div>
          <% end %>
        </div>
      <% end %>

      <%!-- Settings Categories --%>
      <%= for {category, settings} <- @config_settings_with_sources do %>
        <div class="space-y-2">
          <h3 class="font-semibold flex items-center gap-2 px-1">
            <.icon name={category_icon(category)} class="w-4 h-4 opacity-60" />
            {category}
          </h3>

          <div class="bg-base-200 rounded-box divide-y divide-base-300">
            <%= for setting <- settings do %>
              <div class="p-3 sm:p-4">
                <%!-- Mobile: stacked layout, Desktop: flex row --%>
                <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4">
                  <%!-- Setting Info --%>
                  <div class="flex-1 min-w-0">
                    <div class="font-medium flex items-center gap-2 flex-wrap">
                      {setting.label}
                      <.setting_source_badge source={setting.source} />
                    </div>
                    <div class="text-xs opacity-50 font-mono truncate">{setting.key}</div>
                  </div>
                  <%!-- Value Control --%>
                  <div class="sm:ml-auto">
                    <.setting_value_control
                      setting={setting}
                      category={category}
                      editable={setting.source != :env}
                    />
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Legend --%>
      <div class="text-xs opacity-60 flex flex-wrap gap-3 sm:gap-4 justify-center">
        <span class="flex items-center gap-1">
          <span class="badge badge-info badge-xs">ENV</span> Environment (read-only)
        </span>
        <span class="flex items-center gap-1">
          <span class="badge badge-primary badge-xs">DB</span> Database stored
        </span>
        <span class="flex items-center gap-1">
          <span class="badge badge-ghost badge-xs">Default</span> Built-in value
        </span>
      </div>
    </div>
    """
  end

  # Setting value control component - uses proper DaisyUI form elements
  attr :setting, :map, required: true
  attr :category, :string, required: true
  attr :editable, :boolean, default: true

  defp setting_value_control(assigns) do
    ~H"""
    <%= cond do %>
      <% is_boolean(@setting.value) -> %>
        <%= if @editable do %>
          <label class="label cursor-pointer gap-2">
            <span class="label-text text-xs">
              {if @setting.value, do: "On", else: "Off"}
            </span>
            <input
              type="checkbox"
              class="toggle toggle-primary toggle-sm"
              checked={@setting.value}
              phx-click="toggle_setting"
              phx-value-key={@setting.key}
              phx-value-value={to_string(!@setting.value)}
              phx-value-category={@category}
            />
          </label>
        <% else %>
          <span class={[
            "badge",
            if(@setting.value, do: "badge-success", else: "badge-ghost")
          ]}>
            {if @setting.value, do: "Enabled", else: "Disabled"}
          </span>
        <% end %>
      <% String.contains?(@setting.key, "secret") or String.contains?(@setting.key, "key") -> %>
        <span class="opacity-40 font-mono">
          <.icon name="hero-lock-closed" class="w-4 h-4 inline" /> ••••••••
        </span>
      <% (is_nil(@setting.value) or @setting.value == "") and not @editable -> %>
        <span class="badge badge-ghost badge-sm">Not set</span>
      <% @editable -> %>
        <label class="input input-sm input-bordered flex items-center gap-2 w-full sm:w-44">
          <input
            type={if @setting.type == :integer, do: "number", else: "text"}
            class="grow font-mono text-sm"
            value={@setting.value || ""}
            placeholder={Map.get(@setting, :placeholder, "")}
            phx-debounce="1000"
            phx-blur="update_setting_form"
            phx-value-key={@setting.key}
            phx-value-category={@category}
          />
          <%= if @setting.type == :integer do %>
            <.icon name="hero-hashtag" class="w-3 h-3 opacity-40" />
          <% end %>
        </label>
      <% true -> %>
        <kbd class="kbd kbd-sm font-mono">{@setting.value}</kbd>
    <% end %>
    """
  end

  # Source badge component
  attr :source, :atom, required: true

  defp setting_source_badge(assigns) do
    ~H"""
    <%= case @source do %>
      <% :env -> %>
        <span class="badge badge-info badge-sm">ENV</span>
      <% :database -> %>
        <span class="badge badge-primary badge-sm">DB</span>
      <% :yaml -> %>
        <span class="badge badge-secondary badge-sm">YAML</span>
      <% _ -> %>
        <span class="badge badge-ghost badge-sm">Default</span>
    <% end %>
    """
  end

  # Category icons helper
  defp category_icon("Server"), do: "hero-server"
  defp category_icon("Database"), do: "hero-circle-stack"
  defp category_icon("Authentication"), do: "hero-finger-print"
  defp category_icon("Media"), do: "hero-film"
  defp category_icon("Downloads"), do: "hero-arrow-down-tray"
  defp category_icon("Crash Reporting"), do: "hero-bug-ant"
  defp category_icon("Notifications"), do: "hero-bell"
  defp category_icon("FlareSolverr"), do: "hero-shield-check"
  defp category_icon(_), do: "hero-cog-6-tooth"

  @doc """
  Renders the Quality Profiles tab content.
  """
  attr :quality_profiles, :list, required: true

  def quality_profiles_tab(assigns) do
    ~H"""
    <div class="p-4 sm:p-6 space-y-4" phx-hook="DownloadFile" id="quality-profiles-section">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h2 class="text-lg font-semibold flex items-center gap-2">
          <.icon name="hero-sparkles" class="w-5 h-5 opacity-60" /> Quality Profiles
          <span class="badge badge-ghost">{length(@quality_profiles)}</span>
        </h2>
        <div class="flex flex-wrap gap-2">
          <button class="btn btn-sm btn-ghost" phx-click="show_browse_presets_modal">
            <.icon name="hero-sparkles" class="w-4 h-4" />
            <span class="hidden sm:inline">Browse</span> Presets
          </button>
          <button class="btn btn-sm btn-ghost" phx-click="show_import_modal">
            <.icon name="hero-arrow-up-tray" class="w-4 h-4" /> Import
          </button>
          <button class="btn btn-sm btn-primary" phx-click="new_quality_profile">
            <.icon name="hero-plus" class="w-4 h-4" /> New
          </button>
        </div>
      </div>

      <%= if @quality_profiles == [] do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>No quality profiles configured yet. Create one to get started.</span>
        </div>
      <% else %>
        <div class="bg-base-200 rounded-box divide-y divide-base-300">
          <%= for profile <- @quality_profiles do %>
            <% standards = profile.quality_standards || %{} %>
            <% video_codecs = get_in(standards, [:preferred_video_codecs]) || [] %>
            <% resolutions = get_in(standards, [:preferred_resolutions]) || [] %>
            <% movie_min = get_in(standards, [:movie_min_size_mb]) %>
            <% movie_max = get_in(standards, [:movie_max_size_mb]) %>
            <% episode_min = get_in(standards, [:episode_min_size_mb]) %>
            <% episode_max = get_in(standards, [:episode_max_size_mb]) %>

            <div class="p-3 sm:p-4">
              <%!-- Mobile: stacked, Desktop: flex row --%>
              <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <%!-- Profile Info --%>
                <div class="flex-1 min-w-0">
                  <div class="font-semibold flex items-center gap-2 flex-wrap">
                    {profile.name}
                    <%= if profile.is_system do %>
                      <span class="badge badge-primary badge-xs">System</span>
                    <% end %>
                  </div>
                  <div class="text-xs opacity-60 flex flex-wrap gap-x-3 gap-y-1 mt-1">
                    <%= if video_codecs != [] do %>
                      <span>
                        <span class="font-medium">Codecs:</span>
                        {Enum.take(video_codecs, 3) |> Enum.join(", ")}
                        <%= if length(video_codecs) > 3 do %>
                          <span class="opacity-50">+{length(video_codecs) - 3}</span>
                        <% end %>
                      </span>
                    <% end %>
                    <%= if resolutions != [] do %>
                      <span>
                        <span class="font-medium">Res:</span>
                        {Enum.take(resolutions, 2) |> Enum.join(", ")}
                        <%= if length(resolutions) > 2 do %>
                          <span class="opacity-50">+{length(resolutions) - 2}</span>
                        <% end %>
                      </span>
                    <% end %>
                    <%= if movie_min || movie_max do %>
                      <span class="hidden sm:inline">
                        <span class="font-medium">Movies:</span>
                        {movie_min || "0"}-{movie_max || "∞"}MB
                      </span>
                    <% end %>
                    <%= if episode_min || episode_max do %>
                      <span class="hidden sm:inline">
                        <span class="font-medium">Episodes:</span>
                        {episode_min || "0"}-{episode_max || "∞"}MB
                      </span>
                    <% end %>
                  </div>
                </div>

                <%!-- Actions --%>
                <div class="join ml-auto sm:ml-0">
                  <button
                    class="btn btn-sm btn-ghost join-item"
                    phx-click="edit_quality_profile"
                    phx-value-id={profile.id}
                    title="Edit"
                  >
                    <.icon name="hero-pencil" class="w-4 h-4" />
                  </button>
                  <button
                    class="btn btn-sm btn-ghost join-item"
                    phx-click="duplicate_quality_profile"
                    phx-value-id={profile.id}
                    title="Duplicate"
                  >
                    <.icon name="hero-document-duplicate" class="w-4 h-4" />
                  </button>
                  <div class="dropdown dropdown-end">
                    <label tabindex="0" class="btn btn-sm btn-ghost join-item" title="Export">
                      <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                    </label>
                    <ul
                      tabindex="0"
                      class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-32"
                    >
                      <li>
                        <button
                          phx-click="export_quality_profile"
                          phx-value-id={profile.id}
                          phx-value-format="json"
                        >
                          JSON
                        </button>
                      </li>
                      <li>
                        <button
                          phx-click="export_quality_profile"
                          phx-value-id={profile.id}
                          phx-value-format="yaml"
                        >
                          YAML
                        </button>
                      </li>
                    </ul>
                  </div>
                  <button
                    class="btn btn-sm btn-ghost join-item text-error"
                    phx-click="delete_quality_profile"
                    phx-value-id={profile.id}
                    data-confirm="Are you sure you want to delete this quality profile?"
                    title="Delete"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the Download Clients tab content.
  """
  attr :download_clients, :list, required: true
  attr :client_health, :map, required: true

  def download_clients_tab(assigns) do
    ~H"""
    <div class="p-4 sm:p-6 space-y-4">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h2 class="text-lg font-semibold flex items-center gap-2">
          <.icon name="hero-arrow-down-tray" class="w-5 h-5 opacity-60" /> Download Clients
          <span class="badge badge-ghost">{length(@download_clients)}</span>
        </h2>
        <button class="btn btn-sm btn-primary" phx-click="new_download_client">
          <.icon name="hero-plus" class="w-4 h-4" /> New
        </button>
      </div>

      <%= if @download_clients == [] do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>
            No download clients configured yet. Add qBittorrent or Transmission to get started.
          </span>
        </div>
      <% else %>
        <div class="bg-base-200 rounded-box divide-y divide-base-300">
          <%= for client <- @download_clients do %>
            <% health = Map.get(@client_health, client.id, %{status: :unknown}) %>
            <% is_runtime = Settings.runtime_config?(client) %>

            <div class="p-3 sm:p-4">
              <%!-- Mobile: stacked, Desktop: flex row --%>
              <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <%!-- Client Info --%>
                <div class="flex-1 min-w-0">
                  <div class="font-semibold flex items-center gap-2 flex-wrap">
                    {client.name}
                    <%= if is_runtime do %>
                      <span
                        class="badge badge-primary badge-xs tooltip"
                        data-tip="Configured via environment variables (read-only)"
                      >
                        <.icon name="hero-lock-closed" class="w-3 h-3" /> ENV
                      </span>
                    <% end %>
                  </div>
                  <div class="text-xs opacity-60 mt-1 truncate">
                    <span class="font-mono">
                      {if client.use_ssl, do: "https://", else: "http://"}{client.host}:{client.port}
                    </span>
                    <%= if client.category do %>
                      <span class="ml-2">Category: {client.category}</span>
                    <% end %>
                  </div>
                </div>

                <%!-- Status Badges + Actions row --%>
                <div class="flex flex-wrap items-center gap-2">
                  <%!-- Status Badges --%>
                  <span class="badge badge-sm badge-outline">{client.type}</span>
                  <span class={[
                    "badge badge-sm",
                    if(client.enabled, do: "badge-success", else: "badge-ghost")
                  ]}>
                    {if client.enabled, do: "Enabled", else: "Disabled"}
                  </span>
                  <span class={"badge badge-sm #{health_status_badge_class(health.status)}"}>
                    <.icon name={health_status_icon(health.status)} class="w-3 h-3 mr-1" />
                    {health_status_label(health.status)}
                  </span>
                  <%= if health.status == :unhealthy and health[:error] do %>
                    <div class="tooltip tooltip-left" data-tip={health.error}>
                      <.icon name="hero-information-circle" class="w-4 h-4 text-error" />
                    </div>
                  <% end %>
                  <%= if health.status == :healthy and health[:details] && Map.get(health.details, :version) do %>
                    <div
                      class="tooltip tooltip-left"
                      data-tip={"Version: #{health.details.version}"}
                    >
                      <.icon name="hero-information-circle" class="w-4 h-4 text-success" />
                    </div>
                  <% end %>

                  <%!-- Actions --%>
                  <div class="join ml-auto sm:ml-2">
                    <button
                      class="btn btn-sm btn-ghost join-item"
                      phx-click="test_download_client"
                      phx-value-id={client.id}
                      title="Test Connection"
                    >
                      <.icon name="hero-signal" class="w-4 h-4" />
                    </button>
                    <%= if is_runtime do %>
                      <div class="tooltip" data-tip="Cannot edit runtime-configured clients">
                        <button class="btn btn-sm btn-ghost join-item" disabled>
                          <.icon name="hero-pencil" class="w-4 h-4 opacity-30" />
                        </button>
                      </div>
                      <div class="tooltip" data-tip="Cannot delete runtime-configured clients">
                        <button class="btn btn-sm btn-ghost join-item" disabled>
                          <.icon name="hero-trash" class="w-4 h-4 opacity-30" />
                        </button>
                      </div>
                    <% else %>
                      <button
                        class="btn btn-sm btn-ghost join-item"
                        phx-click="edit_download_client"
                        phx-value-id={client.id}
                        title="Edit"
                      >
                        <.icon name="hero-pencil" class="w-4 h-4" />
                      </button>
                      <button
                        class="btn btn-sm btn-ghost join-item text-error"
                        phx-click="delete_download_client"
                        phx-value-id={client.id}
                        data-confirm="Are you sure you want to delete this download client?"
                        title="Delete"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the Indexers tab content.
  Shows both configured indexers (Prowlarr/Jackett) and enabled library indexers.
  """
  attr :indexers, :list, required: true
  attr :indexer_health, :map, required: true
  attr :library_indexers, :list, required: true
  attr :library_indexer_stats, :map, required: true
  attr :cardigann_enabled, :boolean, required: true
  attr :recently_disabled_indexer, :any, default: nil
  attr :flaresolverr_available, :boolean, default: false

  def indexers_tab(assigns) do
    # Calculate total count of enabled indexers
    assigns =
      assign(
        assigns,
        :total_indexers,
        length(assigns.indexers) + length(assigns.library_indexers)
      )

    ~H"""
    <div class="p-4 sm:p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h2 class="text-lg font-semibold flex items-center gap-2">
          <.icon name="hero-magnifying-glass" class="w-5 h-5 opacity-60" /> Indexers
          <span class="badge badge-ghost">{@total_indexers}</span>
        </h2>
        <div class="flex gap-2">
          <%!-- Add Indexer Dropdown --%>
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-sm btn-primary">
              <.icon name="hero-plus" class="w-4 h-4" /> Add Indexer
              <.icon name="hero-chevron-down" class="w-3 h-3" />
            </div>
            <ul
              tabindex="0"
              class="dropdown-content z-[1] menu p-2 shadow bg-base-200 rounded-box w-64"
            >
              <li>
                <button phx-click="new_indexer" class="flex items-start gap-3">
                  <.icon name="hero-server" class="w-5 h-5 mt-0.5 opacity-60" />
                  <div class="text-left">
                    <div class="font-medium">Connect to Prowlarr/Jackett</div>
                    <div class="text-xs text-base-content/60">
                      Use an existing indexer aggregator
                    </div>
                  </div>
                </button>
              </li>
              <%= if @cardigann_enabled do %>
                <li>
                  <button phx-click="show_indexer_library" class="flex items-start gap-3">
                    <.icon name="hero-book-open" class="w-5 h-5 mt-0.5 opacity-60" />
                    <div class="text-left">
                      <div class="font-medium">Browse Indexer Library</div>
                      <div class="text-xs text-base-content/60">
                        {@library_indexer_stats.total} indexers available
                      </div>
                    </div>
                  </button>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>

      <%= if @indexers == [] and @library_indexers == [] do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>
            No indexers configured yet. Add a Prowlarr/Jackett connection or browse the indexer library to get started.
          </span>
        </div>
      <% else %>
        <%!-- Configured Indexers Section (Prowlarr/Jackett) --%>
        <%= if @indexers != [] do %>
          <div class="space-y-3">
            <h3 class="text-sm font-medium text-base-content/70 flex items-center gap-2">
              <.icon name="hero-server" class="w-4 h-4" /> Indexer Connections
              <span class="badge badge-ghost badge-sm">{length(@indexers)}</span>
            </h3>
            <div class="bg-base-200 rounded-box divide-y divide-base-300">
              <%= for indexer <- @indexers do %>
                <% health = Map.get(@indexer_health, indexer.id, %{status: :unknown}) %>
                <% is_runtime = Settings.runtime_config?(indexer) %>

                <div class="p-3 sm:p-4">
                  <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                    <div class="flex-1 min-w-0">
                      <div class="font-semibold flex items-center gap-2 flex-wrap">
                        {indexer.name}
                        <%= if is_runtime do %>
                          <span
                            class="badge badge-primary badge-xs tooltip"
                            data-tip="Configured via environment variables (read-only)"
                          >
                            <.icon name="hero-lock-closed" class="w-3 h-3" /> ENV
                          </span>
                        <% end %>
                      </div>
                      <div class="text-xs opacity-60 mt-1 truncate">
                        <span class="font-mono">{indexer.base_url}</span>
                      </div>
                    </div>

                    <div class="flex flex-wrap items-center gap-2">
                      <span class="badge badge-sm badge-outline">
                        {format_indexer_type(indexer.type)}
                      </span>
                      <span class={[
                        "badge badge-sm",
                        if(indexer.enabled, do: "badge-success", else: "badge-ghost")
                      ]}>
                        {if indexer.enabled, do: "Enabled", else: "Disabled"}
                      </span>
                      <span class={"badge badge-sm #{health_status_badge_class(health.status)}"}>
                        <.icon name={health_status_icon(health.status)} class="w-3 h-3 mr-1" />
                        {health_status_label(health.status)}
                      </span>
                      <%= if health.status == :unhealthy and health[:error] do %>
                        <div class="tooltip tooltip-left" data-tip={health.error}>
                          <.icon name="hero-information-circle" class="w-4 h-4 text-error" />
                        </div>
                      <% end %>
                      <%= if health.status == :healthy and health[:details] && Map.get(health.details, :version) do %>
                        <div
                          class="tooltip tooltip-left"
                          data-tip={"Version: #{health.details.version}"}
                        >
                          <.icon name="hero-information-circle" class="w-4 h-4 text-success" />
                        </div>
                      <% end %>
                      <%= if health[:consecutive_failures] && health.consecutive_failures > 0 do %>
                        <div
                          class="tooltip tooltip-left"
                          data-tip={"#{health.consecutive_failures} consecutive failures"}
                        >
                          <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-warning" />
                        </div>
                      <% end %>

                      <div class="join ml-auto sm:ml-2">
                        <button
                          class="btn btn-sm btn-ghost join-item"
                          phx-click="test_indexer"
                          phx-value-id={indexer.id}
                          title="Test Connection"
                        >
                          <.icon name="hero-signal" class="w-4 h-4" />
                        </button>
                        <%= if is_runtime do %>
                          <div class="tooltip" data-tip="Cannot edit runtime-configured indexers">
                            <button class="btn btn-sm btn-ghost join-item" disabled>
                              <.icon name="hero-pencil" class="w-4 h-4 opacity-30" />
                            </button>
                          </div>
                          <div
                            class="tooltip"
                            data-tip="Cannot delete runtime-configured indexers"
                          >
                            <button class="btn btn-sm btn-ghost join-item" disabled>
                              <.icon name="hero-trash" class="w-4 h-4 opacity-30" />
                            </button>
                          </div>
                        <% else %>
                          <button
                            class="btn btn-sm btn-ghost join-item"
                            phx-click="edit_indexer"
                            phx-value-id={indexer.id}
                            title="Edit"
                          >
                            <.icon name="hero-pencil" class="w-4 h-4" />
                          </button>
                          <button
                            class="btn btn-sm btn-ghost join-item text-error"
                            phx-click="delete_indexer"
                            phx-value-id={indexer.id}
                            data-confirm="Are you sure you want to delete this indexer?"
                            title="Delete"
                          >
                            <.icon name="hero-trash" class="w-4 h-4" />
                          </button>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
        <%!-- Library Indexers Section --%>
        <%= if @library_indexers != [] or @recently_disabled_indexer do %>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-medium text-base-content/70 flex items-center gap-2">
                <.icon name="hero-book-open" class="w-4 h-4" /> Library Indexers
                <span class="badge badge-ghost badge-sm">{length(@library_indexers)}</span>
              </h3>
              <button
                phx-click="show_indexer_library"
                class="btn btn-xs btn-ghost text-primary"
                title="Browse and add more indexers from the library"
              >
                <.icon name="hero-plus" class="w-3 h-3" /> Add More
              </button>
            </div>
            <%!-- Undo Banner for Recently Disabled Indexer --%>
            <%= if @recently_disabled_indexer do %>
              <div class="alert alert-warning shadow-sm">
                <.icon name="hero-arrow-uturn-left" class="w-5 h-5" />
                <span>
                  <strong>{@recently_disabled_indexer.name}</strong> was disabled
                </span>
                <div class="flex gap-2">
                  <button class="btn btn-sm btn-ghost" phx-click="undo_disable_library_indexer">
                    Undo
                  </button>
                  <button
                    class="btn btn-sm btn-ghost btn-circle"
                    phx-click="dismiss_undo_banner"
                    title="Dismiss"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              </div>
            <% end %>
            <div class="bg-base-200 rounded-box divide-y divide-base-300">
              <%= for indexer <- @library_indexers do %>
                <div class="p-3 sm:p-4">
                  <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                    <div class="flex-1 min-w-0">
                      <div class="font-semibold flex items-center gap-2 flex-wrap">
                        {indexer.name}
                        <span class={"badge badge-xs #{library_indexer_type_badge_class(indexer.type)}"}>
                          {indexer.type}
                        </span>
                        <%= if indexer.language do %>
                          <span class="badge badge-xs badge-ghost">{indexer.language}</span>
                        <% end %>
                      </div>
                      <%= if indexer.description do %>
                        <div class="text-xs opacity-60 mt-1 line-clamp-1">
                          {indexer.description}
                        </div>
                      <% end %>
                    </div>

                    <div class="flex flex-wrap items-center gap-2 sm:gap-3">
                      <%!-- Status badges --%>
                      <%= if indexer.health_status not in [nil, "unknown"] do %>
                        <span class={"badge badge-sm #{library_health_status_badge_class(indexer.health_status)}"}>
                          {library_health_status_label(indexer.health_status)}
                        </span>
                      <% end %>
                      <%= if needs_library_config?(indexer) do %>
                        <div class="tooltip" data-tip="This indexer requires configuration">
                          <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-warning" />
                        </div>
                      <% end %>

                      <%!-- Divider --%>
                      <div class="hidden sm:block w-px h-5 bg-base-300"></div>

                      <%!-- Enable/Disable toggle --%>
                      <div
                        class="tooltip"
                        data-tip={if indexer.enabled, do: "Disable", else: "Enable"}
                      >
                        <input
                          type="checkbox"
                          class="toggle toggle-success toggle-sm"
                          checked={indexer.enabled}
                          phx-click="toggle_library_indexer"
                          phx-value-id={indexer.id}
                        />
                      </div>

                      <%!-- FlareSolverr toggle with label --%>
                      <%= if @flaresolverr_available do %>
                        <div class="flex items-center gap-1.5">
                          <div
                            class="tooltip tooltip-left"
                            data-tip={
                              if indexer.flaresolverr_required,
                                do: "Cloudflare bypass (recommended for this indexer)",
                                else: "Enable Cloudflare bypass via FlareSolverr"
                            }
                          >
                            <label class="flex items-center gap-1.5 cursor-pointer">
                              <.icon
                                name="hero-shield-check"
                                class={"w-4 h-4 #{if(indexer.flaresolverr_enabled, do: "text-warning", else: "text-base-content/30")}"}
                              />
                              <span class="text-xs text-base-content/60 hidden sm:inline">CF</span>
                              <input
                                type="checkbox"
                                class={[
                                  "toggle toggle-xs",
                                  if(indexer.flaresolverr_required,
                                    do: "toggle-warning",
                                    else: "toggle-info"
                                  )
                                ]}
                                checked={indexer.flaresolverr_enabled}
                                phx-click="toggle_library_flaresolverr"
                                phx-value-id={indexer.id}
                              />
                            </label>
                          </div>
                        </div>
                      <% end %>

                      <%!-- Configure button (for private/semi-private indexers) --%>
                      <%= if indexer.type in ["private", "semi-private"] do %>
                        <button
                          class="btn btn-sm btn-ghost"
                          phx-click="configure_library_indexer"
                          phx-value-id={indexer.id}
                          title="Configure credentials"
                        >
                          <.icon name="hero-cog-6-tooth" class="w-4 h-4" />
                        </button>
                      <% end %>

                      <%!-- Test button --%>
                      <button
                        class="btn btn-sm btn-ghost"
                        phx-click="test_library_indexer"
                        phx-value-id={indexer.id}
                        title="Test Connection"
                      >
                        <.icon name="hero-signal" class="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Helper functions for library indexer display
  defp library_indexer_type_badge_class("public"), do: "badge-success"
  defp library_indexer_type_badge_class("private"), do: "badge-error"
  defp library_indexer_type_badge_class("semi-private"), do: "badge-warning"
  defp library_indexer_type_badge_class(_), do: "badge-ghost"

  defp library_health_status_badge_class("healthy"), do: "badge-success"
  defp library_health_status_badge_class("degraded"), do: "badge-warning"
  defp library_health_status_badge_class("unhealthy"), do: "badge-error"
  defp library_health_status_badge_class(_), do: "badge-ghost"

  defp library_health_status_label("healthy"), do: "Healthy"
  defp library_health_status_label("degraded"), do: "Degraded"
  defp library_health_status_label("unhealthy"), do: "Unhealthy"
  defp library_health_status_label(_), do: "Unknown"

  defp needs_library_config?(%{type: "public"}), do: false

  defp needs_library_config?(%{type: type, config: nil})
       when type in ["private", "semi-private"],
       do: true

  defp needs_library_config?(%{type: type, config: config})
       when type in ["private", "semi-private"] and config == %{},
       do: true

  defp needs_library_config?(_), do: false

  @doc """
  Renders the Library Paths tab content.
  """
  attr :library_paths, :list, required: true

  def library_paths_tab(assigns) do
    ~H"""
    <div class="p-4 sm:p-6 space-y-4">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h2 class="text-lg font-semibold flex items-center gap-2">
          <.icon name="hero-folder" class="w-5 h-5 opacity-60" /> Library Paths
          <span class="badge badge-ghost">{length(@library_paths)}</span>
        </h2>
        <button class="btn btn-sm btn-primary" phx-click="new_library_path">
          <.icon name="hero-plus" class="w-4 h-4" /> New
        </button>
      </div>

      <%= if @library_paths == [] do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>No library paths configured yet. Add a media directory to get started.</span>
        </div>
      <% else %>
        <div class="bg-base-200 rounded-box divide-y divide-base-300">
          <%= for path <- @library_paths do %>
            <div class="p-3 sm:p-4">
              <%!-- Mobile: stacked, Desktop: flex row --%>
              <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <%!-- Path Info --%>
                <div class="flex-1 min-w-0">
                  <div class="font-semibold font-mono text-sm truncate">{path.path}</div>
                  <%= if path.last_scan_at do %>
                    <div class="text-xs opacity-60 mt-1">
                      Last scan: {Calendar.strftime(path.last_scan_at, "%Y-%m-%d %H:%M")}
                    </div>
                  <% end %>
                </div>

                <%!-- Status Badges + Actions row --%>
                <div class="flex flex-wrap items-center gap-2">
                  <%!-- Status Badges --%>
                  <span class="badge badge-sm badge-outline">{path.type}</span>
                  <span class={[
                    "badge badge-sm",
                    if(path.monitored, do: "badge-success", else: "badge-ghost")
                  ]}>
                    {if path.monitored, do: "Monitored", else: "Not Monitored"}
                  </span>

                  <%!-- Actions --%>
                  <div class="join ml-auto sm:ml-2">
                    <button
                      class="btn btn-sm btn-ghost join-item"
                      phx-click="edit_library_path"
                      phx-value-id={path.id}
                      title="Edit"
                    >
                      <.icon name="hero-pencil" class="w-4 h-4" />
                    </button>
                    <button
                      class="btn btn-sm btn-ghost join-item text-error"
                      phx-click="delete_library_path"
                      phx-value-id={path.id}
                      data-confirm="Are you sure you want to delete this library path?"
                      title="Delete"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Modal Components
  # ============================================================================

  @doc """
  Renders the Quality Profile modal.
  """
  attr :quality_profile_form, :any, required: true
  attr :quality_profile_mode, :atom, required: true
  attr :quality_profile_active_tab, :string, required: true

  def quality_profile_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-5xl">
        <h3 class="font-bold text-lg mb-4">
          {if @quality_profile_mode == :new,
            do: "New Quality Profile",
            else: "Edit Quality Profile"}
        </h3>

        <%!-- Tab Navigation --%>
        <div role="tablist" class="tabs tabs-bordered mb-6">
          <button
            type="button"
            role="tab"
            class={["tab", @quality_profile_active_tab == "basic" && "tab-active"]}
            phx-click="change_quality_profile_tab"
            phx-value-tab="basic"
          >
            Basic Info
          </button>
          <button
            type="button"
            role="tab"
            class={["tab", @quality_profile_active_tab == "standards" && "tab-active"]}
            phx-click="change_quality_profile_tab"
            phx-value-tab="standards"
          >
            Quality Standards
          </button>
          <button
            type="button"
            role="tab"
            class={["tab", @quality_profile_active_tab == "metadata" && "tab-active"]}
            phx-click="change_quality_profile_tab"
            phx-value-tab="metadata"
          >
            Metadata Preferences
          </button>
        </div>

        <.form
          for={@quality_profile_form}
          id="quality-profile-form"
          phx-change="validate_quality_profile"
          phx-submit="save_quality_profile"
        >
          <%!-- Basic Info Tab --%>
          <%= if @quality_profile_active_tab == "basic" do %>
            <.quality_profile_basic_tab form={@quality_profile_form} />
          <% end %>

          <%!-- Quality Standards Tab --%>
          <%= if @quality_profile_active_tab == "standards" do %>
            <.quality_profile_standards_tab form={@quality_profile_form} />
          <% end %>

          <%!-- Metadata Preferences Tab --%>
          <%= if @quality_profile_active_tab == "metadata" do %>
            <.quality_profile_metadata_tab form={@quality_profile_form} />
          <% end %>

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_quality_profile_modal">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">Save Profile</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Basic Info tab content for the Quality Profile modal.
  """
  attr :form, :any, required: true

  def quality_profile_basic_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <%!-- System Profile Indicator --%>
      <%= if Ecto.Changeset.get_field(@form.source, :is_system, false) do %>
        <div class="alert alert-warning">
          <.icon name="hero-lock-closed" class="w-5 h-5" />
          <div>
            <div class="font-semibold">System Profile</div>
            <div class="text-sm">
              This is a built-in system profile. Some fields may be restricted.
            </div>
          </div>
        </div>
      <% end %>

      <.input field={@form[:name]} type="text" label="Name" required />

      <.input
        field={@form[:description]}
        type="textarea"
        label="Description"
        rows="3"
      />

      <%!-- Allowed Qualities --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text">
            Allowed Qualities <span class="text-error">*</span>
          </span>
        </label>
        <div class="grid grid-cols-3 gap-2">
          <%= for quality <- ["360p", "480p", "576p", "720p", "1080p", "2160p", "4320p"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[qualities][]"
                value={quality}
                checked={quality in (Ecto.Changeset.get_field(@form.source, :qualities) || [])}
                class="checkbox checkbox-sm"
              />
              <span class="label-text">{quality}</span>
            </label>
          <% end %>
        </div>
        <%= if @form.errors[:qualities] do %>
          <label class="label">
            <span class="label-text-alt text-error">
              {translate_error(@form.errors[:qualities])}
            </span>
          </label>
        <% end %>
      </div>

      <%!-- Upgrade Settings --%>
      <div class="divider">Upgrade Settings</div>

      <.input
        field={@form[:upgrades_allowed]}
        type="checkbox"
        label="Allow Quality Upgrades"
      />

      <%= if Ecto.Changeset.get_field(@form.source, :upgrades_allowed, true) do %>
        <.input
          field={@form[:upgrade_until_quality]}
          type="select"
          label="Upgrade Until Quality"
          options={[
            {"Don't upgrade", nil}
            | Enum.map(["480p", "576p", "720p", "1080p", "2160p", "4320p"], &{&1, &1})
          ]}
        />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the Quality Standards tab content for the Quality Profile modal.
  """
  attr :form, :any, required: true

  def quality_profile_standards_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span class="text-sm">
          Configure quality standards including codecs, bitrates, resolutions, and file sizes. Leave fields empty to allow any value.
        </span>
      </div>

      <%!-- Video Codecs --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred Video Codecs</span>
          <span class="label-text-alt text-xs">In priority order</span>
        </label>
        <div class="grid grid-cols-3 md:grid-cols-5 gap-2">
          <%= for codec <- ["h265", "h264", "av1", "hevc", "x264", "x265", "vc1", "mpeg2", "xvid", "divx"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][preferred_video_codecs][]"
                value={codec}
                checked={
                  codec in (get_in(
                              Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                              [:preferred_video_codecs]
                            ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{codec}</span>
            </label>
          <% end %>
        </div>
      </div>

      <%!-- Audio Settings --%>
      <div class="divider">Audio Settings</div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred Audio Codecs</span>
        </label>
        <div class="grid grid-cols-3 md:grid-cols-5 gap-2">
          <%= for codec <- ["aac", "ac3", "eac3", "dts", "dts-hd", "truehd", "atmos", "flac", "mp3", "opus"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][preferred_audio_codecs][]"
                value={codec}
                checked={
                  codec in (get_in(
                              Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                              [:preferred_audio_codecs]
                            ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{codec}</span>
            </label>
          <% end %>
        </div>
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred Audio Channels</span>
        </label>
        <div class="grid grid-cols-3 md:grid-cols-4 gap-2">
          <%= for channels <- ["1.0", "2.0", "2.1", "5.1", "6.1", "7.1", "7.1.2", "7.1.4"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][preferred_audio_channels][]"
                value={channels}
                checked={
                  channels in (get_in(
                                 Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                                 [:preferred_audio_channels]
                               ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{channels}</span>
            </label>
          <% end %>
        </div>
      </div>

      <%!-- Resolution Settings --%>
      <div class="divider">Resolution Settings</div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Minimum Resolution</span>
          </label>
          <select
            name="quality_profile[quality_standards][min_resolution]"
            class="select select-bordered w-full"
          >
            <option value="">No minimum</option>
            <%= for res <- ["360p", "480p", "576p", "720p", "1080p", "2160p", "4320p"] do %>
              <option
                value={res}
                selected={
                  res ==
                    get_in(
                      Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                      [:min_resolution]
                    )
                }
              >
                {res}
              </option>
            <% end %>
          </select>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text">Maximum Resolution</span>
          </label>
          <select
            name="quality_profile[quality_standards][max_resolution]"
            class="select select-bordered w-full"
          >
            <option value="">No maximum</option>
            <%= for res <- ["360p", "480p", "576p", "720p", "1080p", "2160p", "4320p"] do %>
              <option
                value={res}
                selected={
                  res ==
                    get_in(
                      Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                      [:max_resolution]
                    )
                }
              >
                {res}
              </option>
            <% end %>
          </select>
        </div>
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred Resolutions</span>
        </label>
        <div class="grid grid-cols-3 md:grid-cols-4 gap-2">
          <%= for res <- ["360p", "480p", "576p", "720p", "1080p", "2160p", "4320p"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][preferred_resolutions][]"
                value={res}
                checked={
                  res in (get_in(
                            Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                            [:preferred_resolutions]
                          ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{res}</span>
            </label>
          <% end %>
        </div>
      </div>

      <%!-- Source Preferences --%>
      <div class="divider">Source Preferences</div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred Sources</span>
          <span class="label-text-alt text-xs">In priority order</span>
        </label>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
          <%= for source <- ["BluRay", "REMUX", "WEB-DL", "WEBRip", "HDTV", "SDTV", "DVD", "DVDRip", "BDRip"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][preferred_sources][]"
                value={source}
                checked={
                  source in (get_in(
                               Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                               [:preferred_sources]
                             ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{source}</span>
            </label>
          <% end %>
        </div>
      </div>

      <%!-- Bitrate Ranges --%>
      <div class="divider">Bitrate Ranges</div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Video Bitrate (Mbps)</span>
        </label>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][min_video_bitrate_mbps]"
              placeholder="Min"
              step="0.1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:min_video_bitrate_mbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Minimum</span>
            </label>
          </div>
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][max_video_bitrate_mbps]"
              placeholder="Max"
              step="0.1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:max_video_bitrate_mbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Maximum</span>
            </label>
          </div>
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][preferred_video_bitrate_mbps]"
              placeholder="Preferred"
              step="0.1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:preferred_video_bitrate_mbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Preferred</span>
            </label>
          </div>
        </div>
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Audio Bitrate (kbps)</span>
        </label>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][min_audio_bitrate_kbps]"
              placeholder="Min"
              step="1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:min_audio_bitrate_kbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Minimum</span>
            </label>
          </div>
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][max_audio_bitrate_kbps]"
              placeholder="Max"
              step="1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:max_audio_bitrate_kbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Maximum</span>
            </label>
          </div>
          <div>
            <input
              type="number"
              name="quality_profile[quality_standards][preferred_audio_bitrate_kbps]"
              placeholder="Preferred"
              step="1"
              min="0"
              value={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                  [:preferred_audio_bitrate_kbps]
                )
              }
              class="input input-bordered w-full"
            />
            <label class="label">
              <span class="label-text-alt">Preferred</span>
            </label>
          </div>
        </div>
      </div>

      <%!-- File Size Constraints --%>
      <div class="divider">File Size Constraints (MB)</div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">Movie File Sizes</span>
          </label>
          <div class="space-y-2">
            <div>
              <input
                type="number"
                name="quality_profile[quality_standards][movie_min_size_mb]"
                placeholder="Min size (MB)"
                step="1"
                min="0"
                value={
                  get_in(
                    Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                    [:movie_min_size_mb]
                  )
                }
                class="input input-bordered w-full"
              />
              <label class="label">
                <span class="label-text-alt">Minimum</span>
              </label>
            </div>
            <div>
              <input
                type="number"
                name="quality_profile[quality_standards][movie_max_size_mb]"
                placeholder="Max size (MB)"
                step="1"
                min="0"
                value={
                  get_in(
                    Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                    [:movie_max_size_mb]
                  )
                }
                class="input input-bordered w-full"
              />
              <label class="label">
                <span class="label-text-alt">Maximum</span>
              </label>
            </div>
          </div>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">Episode File Sizes</span>
          </label>
          <div class="space-y-2">
            <div>
              <input
                type="number"
                name="quality_profile[quality_standards][episode_min_size_mb]"
                placeholder="Min size (MB)"
                step="1"
                min="0"
                value={
                  get_in(
                    Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                    [:episode_min_size_mb]
                  )
                }
                class="input input-bordered w-full"
              />
              <label class="label">
                <span class="label-text-alt">Minimum</span>
              </label>
            </div>
            <div>
              <input
                type="number"
                name="quality_profile[quality_standards][episode_max_size_mb]"
                placeholder="Max size (MB)"
                step="1"
                min="0"
                value={
                  get_in(
                    Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                    [:episode_max_size_mb]
                  )
                }
                class="input input-bordered w-full"
              />
              <label class="label">
                <span class="label-text-alt">Maximum</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <%!-- HDR/Dolby Vision --%>
      <div class="divider">HDR/Dolby Vision</div>

      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Preferred HDR Formats</span>
        </label>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
          <%= for format <- ["hdr10", "hdr10+", "dolby_vision", "hlg"] do %>
            <label class="label cursor-pointer justify-start gap-2">
              <input
                type="checkbox"
                name="quality_profile[quality_standards][hdr_formats][]"
                value={format}
                checked={
                  format in (get_in(
                               Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                               [:hdr_formats]
                             ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text text-sm">{String.upcase(format)}</span>
            </label>
          <% end %>
        </div>
      </div>

      <div class="form-control">
        <label class="label cursor-pointer justify-start gap-3">
          <input
            type="checkbox"
            name="quality_profile[quality_standards][require_hdr]"
            value="true"
            checked={
              get_in(
                Ecto.Changeset.get_field(@form.source, :quality_standards, %{}),
                [:require_hdr]
              ) == true
            }
            class="checkbox checkbox-primary"
          />
          <div>
            <span class="label-text font-semibold">Require HDR</span>
            <p class="text-xs text-base-content/70">
              Only accept files with HDR support
            </p>
          </div>
        </label>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Metadata Preferences tab content for the Quality Profile modal.
  """
  attr :form, :any, required: true

  def quality_profile_metadata_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span class="text-sm">
          Configure metadata provider preferences, language settings, and auto-fetch options.
        </span>
      </div>

      <%!-- Provider Priority --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text font-semibold">Provider Priority</span>
          <span class="label-text-alt text-xs">Providers are tried in order</span>
        </label>
        <div class="space-y-2">
          <%= for provider <- ["metadata_relay", "tvdb", "tmdb", "omdb"] do %>
            <label class="label cursor-pointer justify-start gap-2 bg-base-200 rounded-lg px-4 py-2">
              <input
                type="checkbox"
                name="quality_profile[metadata_preferences][provider_priority][]"
                value={provider}
                checked={
                  provider in (get_in(
                                 Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                                 [:provider_priority]
                               ) || [])
                }
                class="checkbox checkbox-sm checkbox-primary"
              />
              <span class="label-text flex-1 font-medium">
                {provider
                |> String.split("_")
                |> Enum.map(&String.capitalize/1)
                |> Enum.join(" ")}
              </span>
            </label>
          <% end %>
        </div>
        <label class="label">
          <span class="label-text-alt text-xs">
            Select and order providers. Checked providers will be tried in the order they appear.
          </span>
        </label>
      </div>

      <%!-- Language & Region --%>
      <div class="divider">Language & Region</div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Language</span>
          </label>
          <input
            type="text"
            name="quality_profile[metadata_preferences][language]"
            placeholder="en-US"
            value={
              get_in(
                Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                [:language]
              )
            }
            class="input input-bordered w-full"
          />
          <label class="label">
            <span class="label-text-alt text-xs">
              Language code (e.g., en-US, ja, fr-FR)
            </span>
          </label>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text">Region</span>
          </label>
          <input
            type="text"
            name="quality_profile[metadata_preferences][region]"
            placeholder="US"
            maxlength="2"
            value={
              get_in(
                Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                [:region]
              )
            }
            class="input input-bordered w-full"
          />
          <label class="label">
            <span class="label-text-alt text-xs">
              2-letter country code (e.g., US, UK, JP)
            </span>
          </label>
        </div>
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text">Fallback Languages</span>
        </label>
        <input
          type="text"
          name="quality_profile[metadata_preferences][fallback_languages_string]"
          placeholder="en, ja, fr"
          value={
            case get_in(
                   Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                   [:fallback_languages]
                 ) do
              nil -> ""
              langs when is_list(langs) -> Enum.join(langs, ", ")
              _ -> ""
            end
          }
          class="input input-bordered w-full"
        />
        <label class="label">
          <span class="label-text-alt text-xs">
            Comma-separated list of language codes to try if primary language is unavailable
          </span>
        </label>
      </div>

      <%!-- Auto-Fetch Settings --%>
      <div class="divider">Auto-Fetch Settings</div>

      <div class="form-control">
        <label class="label cursor-pointer justify-start gap-3">
          <input
            type="checkbox"
            name="quality_profile[metadata_preferences][auto_fetch_enabled]"
            value="true"
            checked={
              get_in(
                Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                [:auto_fetch_enabled]
              ) == true
            }
            class="checkbox checkbox-primary"
          />
          <div>
            <span class="label-text font-semibold">Enable Auto-Fetch</span>
            <p class="text-xs text-base-content/70">
              Automatically fetch and update metadata periodically
            </p>
          </div>
        </label>
      </div>

      <%= if get_in(
               Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
               [:auto_fetch_enabled]
             ) == true do %>
        <div class="form-control">
          <label class="label">
            <span class="label-text">Auto-Refresh Interval (hours)</span>
          </label>
          <input
            type="number"
            name="quality_profile[metadata_preferences][auto_refresh_interval_hours]"
            placeholder="168"
            step="1"
            min="1"
            value={
              get_in(
                Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                [:auto_refresh_interval_hours]
              ) || 168
            }
            class="input input-bordered w-full max-w-xs"
          />
          <label class="label">
            <span class="label-text-alt text-xs">
              How often to refresh metadata (default: 168 hours = 7 days)
            </span>
          </label>
        </div>
      <% end %>

      <%!-- Fallback Behavior --%>
      <div class="divider">Fallback Behavior</div>

      <div class="space-y-3">
        <div class="form-control">
          <label class="label cursor-pointer justify-start gap-3">
            <input
              type="checkbox"
              name="quality_profile[metadata_preferences][fallback_on_provider_failure]"
              value="true"
              checked={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                  [:fallback_on_provider_failure]
                ) == true
              }
              class="checkbox checkbox-primary"
            />
            <div>
              <span class="label-text font-semibold">Fallback on Provider Failure</span>
              <p class="text-xs text-base-content/70">
                Try next provider if current one fails
              </p>
            </div>
          </label>
        </div>

        <div class="form-control">
          <label class="label cursor-pointer justify-start gap-3">
            <input
              type="checkbox"
              name="quality_profile[metadata_preferences][skip_unavailable_providers]"
              value="true"
              checked={
                get_in(
                  Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                  [:skip_unavailable_providers]
                ) == true
              }
              class="checkbox checkbox-primary"
            />
            <div>
              <span class="label-text font-semibold">Skip Unavailable Providers</span>
              <p class="text-xs text-base-content/70">
                Automatically skip providers that are down or unreachable
              </p>
            </div>
          </label>
        </div>
      </div>

      <%!-- Conflict Resolution --%>
      <div class="divider">Conflict Resolution</div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">Conflict Resolution</span>
          </label>
          <select
            name="quality_profile[metadata_preferences][conflict_resolution]"
            class="select select-bordered w-full"
          >
            <option value="">Choose strategy...</option>
            <%= for {label, value} <- [
                  {"Prefer Newer", "prefer_newer"},
                  {"Prefer Older", "prefer_older"},
                  {"Manual", "manual"}
                ] do %>
              <option
                value={value}
                selected={
                  value ==
                    get_in(
                      Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                      [:conflict_resolution]
                    )
                }
              >
                {label}
              </option>
            <% end %>
          </select>
          <label class="label">
            <span class="label-text-alt text-xs">
              How to handle conflicting metadata from different providers
            </span>
          </label>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">Merge Strategy</span>
          </label>
          <select
            name="quality_profile[metadata_preferences][merge_strategy]"
            class="select select-bordered w-full"
          >
            <option value="">Choose strategy...</option>
            <%= for {label, value} <- [
                  {"Union (combine all)", "union"},
                  {"Intersection (only common)", "intersection"},
                  {"Priority (first provider wins)", "priority"}
                ] do %>
              <option
                value={value}
                selected={
                  value ==
                    get_in(
                      Ecto.Changeset.get_field(@form.source, :metadata_preferences, %{}),
                      [:merge_strategy]
                    )
                }
              >
                {label}
              </option>
            <% end %>
          </select>
          <label class="label">
            <span class="label-text-alt text-xs">
              How to merge metadata when multiple providers return data
            </span>
          </label>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Import Quality Profile modal.
  """
  attr :import_error, :string, default: nil

  def import_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">Import Quality Profile</h3>

        <div class="space-y-4">
          <div class="alert alert-info">
            <.icon name="hero-information-circle" class="w-5 h-5" />
            <span class="text-sm">
              Import a quality profile from a remote URL. Supports both JSON and YAML formats.
            </span>
          </div>

          <.form for={%{}} id="import-profile-form" phx-submit="import_quality_profile_url">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">Profile URL</span>
              </label>
              <input
                type="url"
                name="url"
                placeholder="https://example.com/my-quality-profile.json"
                required
                class="input input-bordered w-full"
              />
              <label class="label">
                <span class="label-text-alt text-xs">
                  Enter the URL of a JSON or YAML quality profile
                </span>
              </label>
            </div>

            <%= if @import_error do %>
              <div class="alert alert-error mt-4">
                <.icon name="hero-exclamation-circle" class="w-5 h-5" />
                <span class="text-sm">{@import_error}</span>
              </div>
            <% end %>

            <div class="modal-action">
              <button type="button" class="btn" phx-click="close_import_modal">
                Cancel
              </button>
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-arrow-down-tray" class="w-5 h-5" /> Import
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Browse Presets modal for quality profiles.
  """
  attr :presets, :list, required: true
  attr :selected_category, :atom, default: :all

  def browse_presets_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-6xl max-h-[90vh] flex flex-col">
        <h3 class="font-bold text-lg mb-4 flex items-center gap-2">
          <.icon name="hero-sparkles" class="w-6 h-6" /> Browse Quality Profile Presets
        </h3>

        <%!-- Category filter tabs --%>
        <div class="tabs tabs-boxed mb-4">
          <button
            class={["tab", @selected_category == :all && "tab-active"]}
            phx-click="filter_presets"
            phx-value-category="all"
          >
            All
          </button>
          <button
            class={["tab", @selected_category == :trash_guides && "tab-active"]}
            phx-click="filter_presets"
            phx-value-category="trash_guides"
          >
            TRaSH Guides
          </button>
          <button
            class={["tab", @selected_category == :storage_optimized && "tab-active"]}
            phx-click="filter_presets"
            phx-value-category="storage_optimized"
          >
            Storage Optimized
          </button>
          <button
            class={["tab", @selected_category == :use_case && "tab-active"]}
            phx-click="filter_presets"
            phx-value-category="use_case"
          >
            Use Cases
          </button>
        </div>

        <%!-- Presets grid --%>
        <div class="overflow-y-auto flex-1">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= for preset <- @presets do %>
              <div class="card bg-base-200 shadow-sm hover:shadow-md transition-shadow">
                <div class="card-body p-4 space-y-2">
                  <%!-- Header with name and tags --%>
                  <div class="flex items-start justify-between gap-2">
                    <h4 class="font-semibold text-base">{preset.name}</h4>
                    <button
                      class="btn btn-sm btn-primary"
                      phx-click="import_preset"
                      phx-value-preset-id={preset.id}
                      title="Import this preset"
                    >
                      <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> Import
                    </button>
                  </div>

                  <%!-- Description --%>
                  <p class="text-sm opacity-80 line-clamp-2">{preset.description}</p>

                  <%!-- Tags --%>
                  <div class="flex flex-wrap gap-1">
                    <%= for tag <- Enum.take(preset.tags, 5) do %>
                      <span class="badge badge-sm badge-ghost">{tag}</span>
                    <% end %>
                    <%= if length(preset.tags) > 5 do %>
                      <span class="badge badge-sm badge-ghost opacity-50">
                        +{length(preset.tags) - 5}
                      </span>
                    <% end %>
                  </div>

                  <%!-- Source info --%>
                  <div class="flex items-center justify-between text-xs opacity-60">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-information-circle" class="w-3 h-3" />
                      {preset.source}
                    </span>
                    <%= if preset.source_url do %>
                      <a
                        href={preset.source_url}
                        target="_blank"
                        class="link link-hover flex items-center gap-1"
                      >
                        <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3" /> Docs
                      </a>
                    <% end %>
                  </div>

                  <%!-- Quick specs --%>
                  <% standards = preset.profile_data.quality_standards || %{} %>
                  <% resolutions = get_in(standards, [:preferred_resolutions]) || [] %>
                  <% video_codecs = get_in(standards, [:preferred_video_codecs]) || [] %>
                  <% sources = get_in(standards, [:preferred_sources]) || [] %>

                  <div class="text-xs space-y-1 pt-2 border-t border-base-300">
                    <%= if resolutions != [] do %>
                      <div class="flex gap-2">
                        <span class="font-medium min-w-[4rem]">Resolution:</span>
                        <span class="opacity-70">{Enum.join(resolutions, ", ")}</span>
                      </div>
                    <% end %>
                    <%= if video_codecs != [] do %>
                      <div class="flex gap-2">
                        <span class="font-medium min-w-[4rem]">Codecs:</span>
                        <span class="opacity-70">{Enum.join(video_codecs, ", ")}</span>
                      </div>
                    <% end %>
                    <%= if sources != [] do %>
                      <div class="flex gap-2">
                        <span class="font-medium min-w-[4rem]">Sources:</span>
                        <span class="opacity-70">{Enum.join(sources, ", ")}</span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <%= if @presets == [] do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>No presets found for this category.</span>
            </div>
          <% end %>
        </div>

        <%!-- Footer --%>
        <div class="modal-action mt-4">
          <button type="button" class="btn" phx-click="close_browse_presets_modal">
            Close
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Download Client modal.
  """
  attr :download_client_form, :any, required: true
  attr :download_client_mode, :atom, required: true
  attr :testing_download_client_connection, :boolean, default: false

  def download_client_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">
          {if @download_client_mode == :new,
            do: "New Download Client",
            else: "Edit Download Client"}
        </h3>

        <.form
          for={@download_client_form}
          id="download-client-form"
          phx-change="validate_download_client"
          phx-submit="save_download_client"
        >
          <div class="space-y-4">
            <.input field={@download_client_form[:name]} type="text" label="Name" required />
            <.input
              field={@download_client_form[:type]}
              type="select"
              label="Type"
              options={[
                {"qBittorrent", "qbittorrent"},
                {"Transmission", "transmission"},
                {"SABnzbd", "sabnzbd"},
                {"NZBGet", "nzbget"},
                {"HTTP", "http"}
              ]}
              required
            />
            <.input field={@download_client_form[:host]} type="text" label="Host" required />
            <.input field={@download_client_form[:port]} type="number" label="Port" required />
            <.input field={@download_client_form[:username]} type="text" label="Username" />
            <.input field={@download_client_form[:password]} type="password" label="Password" />
            <.input field={@download_client_form[:api_key]} type="password" label="API Key" />
            <.input field={@download_client_form[:url_base]} type="text" label="URL Base" />
            <.input field={@download_client_form[:category]} type="text" label="Category" />
            <.input
              field={@download_client_form[:download_directory]}
              type="text"
              label="Download Directory"
            />
            <.input field={@download_client_form[:use_ssl]} type="checkbox" label="Use SSL" />
            <.input
              field={@download_client_form[:enabled]}
              type="checkbox"
              label="Enabled"
              checked
            />
            <.input field={@download_client_form[:priority]} type="number" label="Priority" />
          </div>

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_download_client_modal">
              Cancel
            </button>
            <button
              type="button"
              class="btn btn-secondary"
              phx-click="test_download_client_connection"
              disabled={@testing_download_client_connection}
            >
              <%= if @testing_download_client_connection do %>
                <span class="loading loading-spinner loading-sm"></span> Testing...
              <% else %>
                <.icon name="hero-signal" class="w-4 h-4" /> Test Connection
              <% end %>
            </button>
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Indexer modal.
  """
  attr :indexer_form, :any, required: true
  attr :indexer_mode, :atom, required: true
  attr :testing_indexer_connection, :boolean, default: false

  def indexer_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">
          {if @indexer_mode == :new, do: "New Indexer", else: "Edit Indexer"}
        </h3>

        <.form
          for={@indexer_form}
          id="indexer-form"
          phx-change="validate_indexer"
          phx-submit="save_indexer"
        >
          <div class="space-y-4">
            <.input field={@indexer_form[:name]} type="text" label="Name" required />
            <.input
              field={@indexer_form[:type]}
              type="select"
              label="Type"
              options={[
                {"Prowlarr", "prowlarr"},
                {"Jackett", "jackett"},
                {"Public", "public"}
              ]}
              required
            />
            <.input field={@indexer_form[:base_url]} type="text" label="Base URL" required />
            <.input field={@indexer_form[:api_key]} type="password" label="API Key" />
            <.input field={@indexer_form[:enabled]} type="checkbox" label="Enabled" checked />
            <.input field={@indexer_form[:priority]} type="number" label="Priority" />
          </div>

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_indexer_modal">Cancel</button>
            <button
              type="button"
              class="btn btn-secondary"
              phx-click="test_indexer_connection"
              disabled={@testing_indexer_connection}
            >
              <%= if @testing_indexer_connection do %>
                <span class="loading loading-spinner loading-sm"></span> Testing...
              <% else %>
                <.icon name="hero-signal" class="w-4 h-4" /> Test Connection
              <% end %>
            </button>
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Library Path modal.
  """
  attr :library_path_form, :any, required: true
  attr :library_path_mode, :atom, required: true

  def library_path_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">
          {if @library_path_mode == :new, do: "New Library Path", else: "Edit Library Path"}
        </h3>

        <.form
          for={@library_path_form}
          id="library-path-form"
          phx-change="validate_library_path"
          phx-submit="save_library_path"
        >
          <div class="space-y-4">
            <.input field={@library_path_form[:path]} type="text" label="Path" required />
            <.input
              field={@library_path_form[:type]}
              type="select"
              label="Type"
              options={[{"Movies", "movies"}, {"TV Shows", "series"}, {"Mixed", "mixed"}]}
              required
            />
            <.input
              field={@library_path_form[:monitored]}
              type="checkbox"
              label="Monitored"
              checked
            />
          </div>

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_library_path_modal">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Library Indexer Config modal.
  """
  attr :configuring_library_indexer, :any, required: true

  def library_config_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4 flex items-center gap-2">
          <.icon name="hero-cog-6-tooth" class="w-5 h-5 opacity-60" />
          Configure {@configuring_library_indexer.name}
        </h3>

        <div class="alert alert-info mb-4">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>
            Private indexers require authentication. Enter your credentials below.
          </span>
        </div>

        <form id="library-indexer-config-form" phx-submit="save_library_indexer_config">
          <div class="space-y-4">
            <%!-- Username --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text">Username</span>
              </label>
              <input
                type="text"
                name="config[username]"
                value={get_in(@configuring_library_indexer.config || %{}, ["username"])}
                class="input input-bordered"
                placeholder="Your indexer username"
              />
            </div>
            <%!-- Password --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text">Password</span>
              </label>
              <input
                type="password"
                name="config[password]"
                value={get_in(@configuring_library_indexer.config || %{}, ["password"])}
                class="input input-bordered"
                placeholder="Your indexer password"
              />
            </div>
            <%!-- API Key (optional) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text">API Key (if applicable)</span>
              </label>
              <input
                type="password"
                name="config[api_key]"
                value={get_in(@configuring_library_indexer.config || %{}, ["api_key"])}
                class="input input-bordered"
                placeholder="Optional API key"
              />
            </div>
            <%!-- Cookie (optional) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text">Cookie String (if applicable)</span>
              </label>
              <textarea
                name="config[cookie]"
                rows="3"
                class="textarea textarea-bordered"
                placeholder="Optional cookie string for authentication"
              >{get_in(@configuring_library_indexer.config || %{}, ["cookie"])}</textarea>
            </div>
          </div>

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_library_config_modal">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">Save Configuration</button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="close_library_config_modal"></div>
    </div>
    """
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp health_badge(:healthy), do: "badge-success"
  defp health_badge(:unhealthy), do: "badge-error"
  defp health_badge(:unknown), do: "badge-warning"
  defp health_badge(_), do: "badge-ghost"

  defp health_status_badge_class(:healthy), do: "badge-success"
  defp health_status_badge_class(:unhealthy), do: "badge-error"
  defp health_status_badge_class(:unknown), do: "badge-ghost"

  defp health_status_icon(:healthy), do: "hero-check-circle"
  defp health_status_icon(:unhealthy), do: "hero-x-circle"
  defp health_status_icon(:unknown), do: "hero-question-mark-circle"

  defp health_status_label(:healthy), do: "Healthy"
  defp health_status_label(:unhealthy), do: "Unhealthy"
  defp health_status_label(:unknown), do: "Unknown"

  defp format_indexer_type(type) when is_atom(type) do
    type |> to_string() |> String.capitalize()
  end

  defp format_indexer_type(type), do: to_string(type)
end
