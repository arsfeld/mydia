defmodule MydiaWeb.ImportMediaLive.Components do
  @moduledoc """
  Reusable UI components for the Import Media workflow.

  These components break down the import media interface into smaller,
  focused, and testable pieces. Each component is a pure presentation
  function with clearly defined attributes.
  """

  use Phoenix.Component
  import MydiaWeb.CoreComponents

  @doc """
  Renders the progress steps indicator for the import wizard.

  ## Attributes
    * `:step` - Current step (one of: `:select_path`, `:review`, `:importing`, `:complete`)
  """
  attr :step, :atom, required: true

  def progress_steps(assigns) do
    ~H"""
    <ul class="steps steps-horizontal w-full text-xs">
      <li class={"step step-sm " <> if(@step in [:select_path, :review, :importing, :complete], do: "step-primary", else: "")}>
        Select Path
      </li>
      <li class={"step step-sm " <> if(@step in [:review, :importing, :complete], do: "step-primary", else: "")}>
        Review Matches
      </li>
      <li class={"step step-sm " <> if(@step in [:importing, :complete], do: "step-primary", else: "")}>
        Import
      </li>
      <li class={"step step-sm " <> if(@step == :complete, do: "step-primary", else: "")}>
        Complete
      </li>
    </ul>
    """
  end

  @doc """
  Renders the path selection screen where users choose a directory to scan.

  ## Attributes
    * `:library_paths` - List of available library paths
  """
  attr :library_paths, :list, default: []

  def path_selection_screen(assigns) do
    ~H"""
    <div class="flex flex-col items-center">
      <%!-- Hero Section --%>
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mb-4">
          <.icon name="hero-folder-open" class="w-8 h-8 text-primary" />
        </div>
        <h2 class="text-xl font-bold mb-2">Select a Library to Scan</h2>
        <p class="text-sm text-base-content/60 max-w-md">
          Choose one of your configured library paths to discover and import media files.
        </p>
      </div>

      <%!-- Library Paths Grid --%>
      <%= if @library_paths != [] do %>
        <div class="grid gap-3 w-full max-w-2xl">
          <%= for path <- @library_paths do %>
            <button
              type="button"
              class="group card card-compact bg-base-100 border border-base-300 hover:border-primary hover:shadow-lg transition-all duration-200 cursor-pointer text-left"
              phx-click="select_library_path"
              phx-value-path_id={path.id}
            >
              <div class="card-body flex-row items-center gap-4">
                <%!-- Icon based on library type --%>
                <div class={[
                  "flex items-center justify-center w-12 h-12 rounded-lg transition-colors",
                  library_type_bg_class(path.type),
                  "group-hover:scale-105 transition-transform"
                ]}>
                  <.icon name={library_type_icon(path.type)} class="w-6 h-6" />
                </div>

                <%!-- Path info --%>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <span class={[
                      "badge badge-sm",
                      library_type_badge_class(path.type)
                    ]}>
                      {library_type_display(path.type)}
                    </span>
                  </div>
                  <p class="font-mono text-sm truncate text-base-content/80 group-hover:text-base-content">
                    {path.path}
                  </p>
                </div>

                <%!-- Arrow indicator --%>
                <div class="text-base-content/30 group-hover:text-primary group-hover:translate-x-1 transition-all">
                  <.icon name="hero-chevron-right" class="w-5 h-5" />
                </div>
              </div>
            </button>
          <% end %>
        </div>

        <%!-- Hint --%>
        <p class="text-xs text-base-content/50 mt-6 text-center">
          <.icon name="hero-information-circle" class="w-4 h-4 inline -mt-0.5" />
          Need to add more paths? Configure them in
          <a href="/settings/library" class="link link-primary">Library Settings</a>
        </p>
      <% else %>
        <%!-- Empty State --%>
        <div class="card bg-base-200/50 border border-dashed border-base-300 w-full max-w-md">
          <div class="card-body items-center text-center py-12">
            <div class="w-16 h-16 rounded-full bg-warning/10 flex items-center justify-center mb-4">
              <.icon name="hero-folder-plus" class="w-8 h-8 text-warning" />
            </div>
            <h3 class="font-semibold text-lg mb-2">No Library Paths Configured</h3>
            <p class="text-sm text-base-content/60 mb-4">
              Add a library path in Settings to start importing your media files.
            </p>
            <a href="/settings/library" class="btn btn-primary btn-sm gap-2">
              <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Go to Settings
            </a>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions for library type styling
  defp library_type_icon(:series), do: "hero-tv"
  defp library_type_icon(:movies), do: "hero-film"
  defp library_type_icon(:mixed), do: "hero-square-3-stack-3d"
  defp library_type_icon(:music), do: "hero-musical-note"
  defp library_type_icon(:books), do: "hero-book-open"
  defp library_type_icon(:adult), do: "hero-eye-slash"
  defp library_type_icon(_), do: "hero-folder"

  defp library_type_bg_class(:series), do: "bg-info/10 text-info"
  defp library_type_bg_class(:movies), do: "bg-accent/10 text-accent"
  defp library_type_bg_class(:mixed), do: "bg-secondary/10 text-secondary"
  defp library_type_bg_class(:music), do: "bg-success/10 text-success"
  defp library_type_bg_class(:books), do: "bg-warning/10 text-warning"
  defp library_type_bg_class(:adult), do: "bg-error/10 text-error"
  defp library_type_bg_class(_), do: "bg-base-200 text-base-content/70"

  defp library_type_badge_class(:series), do: "badge-info"
  defp library_type_badge_class(:movies), do: "badge-accent"
  defp library_type_badge_class(:mixed), do: "badge-secondary"
  defp library_type_badge_class(:music), do: "badge-success"
  defp library_type_badge_class(:books), do: "badge-warning"
  defp library_type_badge_class(:adult), do: "badge-error"
  defp library_type_badge_class(_), do: "badge-ghost"

  defp library_type_display(:series), do: "TV Series"
  defp library_type_display(:movies), do: "Movies"
  defp library_type_display(:mixed), do: "Mixed"
  defp library_type_display(:music), do: "Music"
  defp library_type_display(:books), do: "Books"
  defp library_type_display(:adult), do: "Adult"
  defp library_type_display(type), do: to_string(type)

  @doc """
  Renders the scanning/matching progress indicator.

  ## Attributes
    * `:scanning` - Whether currently scanning
    * `:matching` - Whether currently matching files
    * `:scan_stats` - Map with stats (`:total`, `:skipped`, `:orphaned`)
  """
  attr :scanning, :boolean, required: true
  attr :matching, :boolean, required: true
  attr :scan_stats, :map, required: true

  def scanning_progress(assigns) do
    ~H"""
    <div class="flex flex-col items-center py-8">
      <%!-- Animated Icon Container --%>
      <div class="relative mb-6">
        <%!-- Pulsing background ring --%>
        <div class={[
          "absolute inset-0 rounded-full animate-ping opacity-20",
          if(@scanning, do: "bg-primary", else: "bg-secondary")
        ]}>
        </div>
        <%!-- Icon container --%>
        <div class={[
          "relative flex items-center justify-center w-20 h-20 rounded-full",
          if(@scanning, do: "bg-primary/10", else: "bg-secondary/10")
        ]}>
          <%= if @scanning do %>
            <.icon name="hero-magnifying-glass" class="w-10 h-10 text-primary animate-pulse" />
          <% else %>
            <.icon name="hero-sparkles" class="w-10 h-10 text-secondary animate-pulse" />
          <% end %>
        </div>
      </div>

      <%!-- Title and description --%>
      <h2 class="text-xl font-bold mb-2">
        {if(@scanning, do: "Scanning Directory", else: "Matching Files")}
      </h2>
      <p class="text-sm text-base-content/60 max-w-md text-center mb-6">
        {if(@scanning,
          do: "Discovering media files in the selected directory...",
          else: "Looking up metadata from TMDB for your media files..."
        )}
      </p>

      <%!-- Progress indicator --%>
      <div class="flex items-center gap-2 text-base-content/50 mb-8">
        <span class="loading loading-dots loading-sm"></span>
        <span class="text-sm">
          {if(@scanning, do: "Scanning in progress", else: "Matching in progress")}
        </span>
      </div>

      <%!-- Stats cards during matching phase --%>
      <%= if @matching do %>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-md">
          <%!-- New Files Card --%>
          <div class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body p-4 items-center text-center">
              <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center mb-2">
                <.icon name="hero-document-text" class="w-5 h-5 text-primary" />
              </div>
              <div class="text-3xl font-bold text-primary">{@scan_stats.total}</div>
              <div class="text-xs text-base-content/60">New files to match</div>
            </div>
          </div>

          <%!-- Skipped Files Card --%>
          <%= if @scan_stats.skipped > 0 do %>
            <div class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body p-4 items-center text-center">
                <div class="w-10 h-10 rounded-full bg-base-200 flex items-center justify-center mb-2">
                  <.icon name="hero-check-circle" class="w-5 h-5 text-base-content/50" />
                </div>
                <div class="text-3xl font-bold text-base-content/50">{@scan_stats.skipped}</div>
                <div class="text-xs text-base-content/60">Already imported</div>
              </div>
            </div>
          <% else %>
            <div class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body p-4 items-center text-center">
                <div class="w-10 h-10 rounded-full bg-success/10 flex items-center justify-center mb-2">
                  <.icon name="hero-check-circle" class="w-5 h-5 text-success" />
                </div>
                <div class="text-3xl font-bold text-success">0</div>
                <div class="text-xs text-base-content/60">Duplicates found</div>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Subtle hint --%>
        <p class="text-xs text-base-content/40 mt-6 text-center">
          This may take a moment depending on the number of files
        </p>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the import progress screen.

  ## Attributes
    * `:import_progress` - Map with `:current`, `:total`, and `:current_file`
  """
  attr :import_progress, :map, required: true

  def import_progress_screen(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body items-center text-center">
        <span class="loading loading-spinner loading-lg text-primary"></span>
        <h2 class="card-title mt-4">Importing Files</h2>
        <p class="text-base-content/70">
          Please wait while files are being imported...
        </p>

        <div class="w-full max-w-md mt-6">
          <progress
            class="progress progress-primary w-full"
            value={@import_progress.current}
            max={@import_progress.total}
          >
          </progress>
          <p class="text-sm text-base-content/60 mt-2">
            {@import_progress.current} / {@import_progress.total} files
          </p>
          <%= if @import_progress.current_file do %>
            <p class="text-xs text-base-content/50 mt-1 truncate">
              Current: {@import_progress.current_file}
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the stats cards for the review screen.

  ## Attributes
    * `:scan_stats` - Map with `:total`, `:matched`, `:unmatched`, `:skipped`, `:orphaned`, `:type_filtered`
  """
  attr :scan_stats, :map, required: true

  def review_stats(assigns) do
    ~H"""
    <div class="stats stats-vertical sm:stats-horizontal shadow-md w-full mb-3 bg-base-100 border border-base-300">
      <div class="stat py-2 px-4">
        <div class="stat-title text-xs">Discovered</div>
        <div class="stat-value text-lg text-primary">{@scan_stats.total}</div>
        <div class="stat-desc text-[10px]">new files</div>
      </div>

      <div class="stat py-2 px-4">
        <div class="stat-title text-xs">Matched</div>
        <div class="stat-value text-lg text-success">{@scan_stats.matched}</div>
        <div class="stat-desc text-[10px]">metadata found</div>
      </div>

      <%= if @scan_stats.unmatched > 0 do %>
        <div class="stat py-2 px-4">
          <div class="stat-title text-xs">Unmatched</div>
          <div class="stat-value text-lg text-warning">{@scan_stats.unmatched}</div>
          <div class="stat-desc text-[10px]">need manual match</div>
        </div>
      <% end %>

      <%= if @scan_stats[:type_filtered] && @scan_stats.type_filtered > 0 do %>
        <div class="stat py-2 px-4">
          <div class="stat-title text-xs">Filtered</div>
          <div class="stat-value text-lg text-info">{@scan_stats.type_filtered}</div>
          <div class="stat-desc text-[10px]">type mismatch</div>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the selection controls for the review screen.

  ## Attributes
    * `:selected_files` - MapSet of selected file indices
  """
  attr :selected_files, :any, required: true

  def selection_controls(assigns) do
    ~H"""
    <%!-- In-flow toolbar (always visible at normal position) --%>
    <div
      id="selection-toolbar"
      phx-hook="StickyToolbar"
      data-fixed-id="selection-toolbar-fixed"
      class="flex items-center justify-between mb-3"
    >
      <div class="flex gap-2">
        <button type="button" class="btn btn-sm btn-outline" phx-click="select_all_files">
          Select All
        </button>
        <button type="button" class="btn btn-sm btn-outline" phx-click="deselect_all_files">
          Deselect All
        </button>
      </div>
      <button
        type="button"
        class="btn btn-sm btn-primary"
        phx-click="start_import"
        disabled={MapSet.size(@selected_files) == 0}
      >
        <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> Import ({MapSet.size(@selected_files)})
      </button>
    </div>

    <%!-- Fixed toolbar (hidden by default, shown when scrolling past in-flow toolbar) --%>
    <div
      id="selection-toolbar-fixed"
      class="hidden fixed top-14 lg:top-0 left-0 lg:left-64 right-0 z-20 bg-base-100 border-b border-base-300 shadow-sm px-4 py-2"
    >
      <div class="flex items-center justify-between max-w-7xl mx-auto">
        <div class="flex gap-2">
          <button type="button" class="btn btn-sm btn-outline" phx-click="select_all_files">
            Select All
          </button>
          <button type="button" class="btn btn-sm btn-outline" phx-click="deselect_all_files">
            Deselect All
          </button>
        </div>
        <button
          type="button"
          class="btn btn-sm btn-primary"
          phx-click="start_import"
          disabled={MapSet.size(@selected_files) == 0}
        >
          <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
          Import ({MapSet.size(@selected_files)})
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders an episode match as a compact list item.

  ## Attributes
    * `:episode` - Episode data with `:index`, `:file`, `:match_result`
    * `:is_selected` - Whether this episode is selected
    * `:is_editing` - Whether this episode is being edited
    * `:edit_form` - Edit form data (if editing)
    * `:search_results` - Search results (if editing)
  """
  attr :episode, :map, required: true
  attr :is_selected, :boolean, required: true
  attr :is_editing, :boolean, required: true
  attr :edit_form, :map, default: nil
  attr :search_results, :list, default: []

  def episode_list_item(assigns) do
    ~H"""
    <% match = @episode.match_result %>
    <li class={"flex items-center gap-3 py-2 px-3 hover:bg-base-200/50 rounded-lg " <> if(@is_selected, do: "bg-primary/10", else: "")}>
      <%= if @is_editing do %>
        <%!-- Edit Form --%>
        <.form
          for={%{}}
          phx-submit="save_edit"
          id={"edit-form-#{@episode.index}"}
          class="flex-1"
        >
          <%!-- Series/Movie Title with Search --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-xs">
                Series/Movie Title
              </span>
            </label>
            <div class="relative">
              <input
                type="text"
                name="edit_form[title]"
                value={@edit_form["title"]}
                class="input input-bordered input-sm w-full"
                phx-change="search_series"
                phx-debounce="300"
                autocomplete="off"
              />
              <%= if @search_results != [] do %>
                <.search_results_dropdown results={@search_results} />
              <% end %>
            </div>
          </div>
          <input
            type="hidden"
            name="edit_form[provider_id]"
            value={@edit_form["provider_id"]}
          />
          <input
            type="hidden"
            name="edit_form[type]"
            value={@edit_form["type"]}
          />
          <%!-- Season Number --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-xs">Season Number</span>
            </label>
            <input
              type="number"
              name="edit_form[season]"
              value={@edit_form["season"]}
              class="input input-bordered input-sm"
              placeholder="e.g., 1"
              min="0"
            />
          </div>
          <%!-- Episode Numbers --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-xs">
                Episode Number(s)
              </span>
            </label>
            <input
              type="text"
              name="edit_form[episodes]"
              value={@edit_form["episodes"]}
              class="input input-bordered input-sm"
              placeholder="e.g., 1, 2, 3"
            />
            <label class="label">
              <span class="label-text-alt text-xs">
                Comma-separated for multi-episode files
              </span>
            </label>
          </div>
          <%!-- Year --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-xs">Year</span>
            </label>
            <input
              type="number"
              name="edit_form[year]"
              value={@edit_form["year"]}
              class="input input-bordered input-sm"
              placeholder="e.g., 2024"
              min="1900"
              max="2100"
            />
          </div>
          <%!-- Action Buttons --%>
          <div class="flex gap-2 justify-end">
            <button
              type="button"
              class="btn btn-ghost btn-sm"
              phx-click="cancel_edit"
            >
              Cancel
            </button>
            <button type="submit" class="btn btn-primary btn-sm">
              <.icon name="hero-check" class="w-4 h-4" /> Save
            </button>
          </div>
        </.form>
      <% else %>
        <%!-- Normal Display --%>
        <input
          type="checkbox"
          class="checkbox checkbox-primary checkbox-sm"
          checked={@is_selected}
          phx-click="toggle_file_selection"
          phx-value-index={@episode.index}
        />
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-3">
            <div class="flex-1 min-w-0">
              <%= if Map.get(match, :match_type) == :partial_match do %>
                <p class="font-semibold text-sm truncate text-warning">
                  {match.title}
                  <%= if match.parsed_info.season do %>
                    - S{String.pad_leading(to_string(match.parsed_info.season), 2, "0")}E{String.pad_leading(
                      to_string(hd(match.parsed_info.episodes || [0])),
                      2,
                      "0"
                    )}
                  <% end %>
                </p>
                <p class="text-xs text-base-content/60 truncate">
                  Parsed from: {Path.basename(@episode.file.path)}
                </p>
                <p class="text-xs text-warning">
                  Episode not in database - will import with parsed info
                </p>
              <% else %>
                <p class="font-medium text-sm truncate">
                  {Path.basename(@episode.file.path)}
                </p>
                <div class="flex items-center gap-2 text-xs text-base-content/60">
                  <%= if match.parsed_info.episodes do %>
                    <span>
                      Ep. {Enum.join(match.parsed_info.episodes, ", ")}
                    </span>
                  <% end %>
                  <span>•</span>
                  <span>{format_file_size(@episode.file.size)}</span>
                </div>
              <% end %>
            </div>
            <div class="flex items-center gap-2">
              <%= if Map.get(match, :match_type) == :partial_match do %>
                <div class="badge badge-xs badge-warning gap-1">
                  <.icon name="hero-exclamation-circle" class="w-3 h-3" /> Partial Match
                </div>
              <% end %>
              <%= if Map.get(match, :manually_edited, false) do %>
                <div class="badge badge-xs badge-info gap-1">
                  <.icon name="hero-pencil" class="w-3 h-3" /> Edited
                </div>
              <% end %>
              <div class={"badge badge-xs " <> confidence_badge_class(match.match_confidence)}>
                {confidence_label(match.match_confidence)}
              </div>
              <button
                type="button"
                class="btn btn-xs btn-ghost"
                phx-click="edit_file"
                phx-value-index={@episode.index}
              >
                <.icon name="hero-pencil" class="w-3 h-3" />
              </button>
              <button
                type="button"
                class="btn btn-xs btn-ghost text-error"
                phx-click="clear_match"
                phx-value-index={@episode.index}
              >
                <.icon name="hero-x-mark" class="w-3 h-3" />
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </li>
    """
  end

  @doc """
  Renders a movie match as a compact list item.

  ## Attributes
    * `:movie` - Movie data with `:index`, `:file`, `:match_result`
    * `:is_selected` - Whether this movie is selected
    * `:is_editing` - Whether this movie is being edited
    * `:edit_form` - Edit form data (if editing)
    * `:search_results` - Search results (if editing)
  """
  attr :movie, :map, required: true
  attr :is_selected, :boolean, required: true
  attr :is_editing, :boolean, required: true
  attr :edit_form, :map, default: nil
  attr :search_results, :list, default: []

  def movie_list_item(assigns) do
    ~H"""
    <% match = @movie.match_result %>
    <li class={"flex items-center gap-3 py-2 px-3 hover:bg-base-200/50 rounded-lg " <> if(@is_selected, do: "bg-primary/10", else: "")}>
      <%= if @is_editing do %>
        <%!-- Edit Form --%>
        <.form
          for={%{}}
          phx-submit="save_edit"
          id={"edit-form-#{@movie.index}"}
          class="flex-1"
        >
          <div class="form-control">
            <label class="label">
              <span class="label-text text-sm">Movie Title</span>
            </label>
            <div class="relative">
              <input
                type="text"
                name="edit_form[title]"
                value={@edit_form["title"]}
                class="input input-bordered input-sm w-full"
                phx-change="search_series"
                phx-debounce="300"
                autocomplete="off"
              />
              <%= if @search_results != [] do %>
                <.search_results_dropdown results={@search_results} />
              <% end %>
            </div>
          </div>
          <input type="hidden" name="edit_form[provider_id]" value={@edit_form["provider_id"]} />
          <input type="hidden" name="edit_form[type]" value={@edit_form["type"]} />
          <input type="hidden" name="edit_form[season]" value="" />
          <input type="hidden" name="edit_form[episodes]" value="" />
          <div class="form-control">
            <label class="label">
              <span class="label-text text-sm">Year</span>
            </label>
            <input
              type="number"
              name="edit_form[year]"
              value={@edit_form["year"]}
              class="input input-bordered input-sm"
              placeholder="e.g., 2024"
              min="1900"
              max="2100"
            />
          </div>
          <div class="flex gap-2 justify-end">
            <button type="button" class="btn btn-ghost btn-sm" phx-click="cancel_edit">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary btn-sm">
              <.icon name="hero-check" class="w-4 h-4" /> Save
            </button>
          </div>
        </.form>
      <% else %>
        <%!-- Normal Display --%>
        <input
          type="checkbox"
          class="checkbox checkbox-primary checkbox-sm"
          checked={@is_selected}
          phx-click="toggle_file_selection"
          phx-value-index={@movie.index}
        />
        <%= if match.metadata.poster_path do %>
          <img
            src={"https://image.tmdb.org/t/p/w92#{match.metadata.poster_path}"}
            alt={match.title}
            class="w-12 h-18 rounded object-cover"
          />
        <% end %>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-3">
            <div class="flex-1 min-w-0">
              <p class="font-semibold text-sm truncate">
                {match.title}
                <%= if match.year do %>
                  ({match.year})
                <% end %>
              </p>
              <p class="text-xs text-base-content/60 truncate">
                {Path.basename(@movie.file.path)}
              </p>
              <p class="text-xs text-base-content/50">
                {format_file_size(@movie.file.size)}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <%= if Map.get(match, :manually_edited, false) do %>
                <div class="badge badge-xs badge-info gap-1">
                  <.icon name="hero-pencil" class="w-3 h-3" /> Edited
                </div>
              <% end %>
              <div class={"badge badge-xs " <> confidence_badge_class(match.match_confidence)}>
                {confidence_label(match.match_confidence)}
              </div>
              <div class="badge badge-xs badge-accent">Movie</div>
              <button
                type="button"
                class="btn btn-xs btn-ghost"
                phx-click="edit_file"
                phx-value-index={@movie.index}
              >
                <.icon name="hero-pencil" class="w-3 h-3" />
              </button>
              <button
                type="button"
                class="btn btn-xs btn-ghost text-error"
                phx-click="clear_match"
                phx-value-index={@movie.index}
              >
                <.icon name="hero-x-mark" class="w-3 h-3" />
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </li>
    """
  end

  @doc """
  Renders an unmatched file as a compact list item.

  ## Attributes
    * `:file` - File data with `:index`, `:file`
    * `:is_editing` - Whether this file is being edited
    * `:edit_form` - Edit form data (if editing)
    * `:search_results` - Search results (if editing)
  """
  attr :file, :map, required: true
  attr :is_editing, :boolean, required: true
  attr :edit_form, :map, default: nil
  attr :search_results, :list, default: []

  def unmatched_file_list_item(assigns) do
    ~H"""
    <li class={"flex items-center gap-3 py-2 px-3 hover:bg-base-200/50 rounded-lg " <> if(!@is_editing, do: "opacity-60", else: "")}>
      <%= if @is_editing do %>
        <.form
          for={%{}}
          phx-submit="save_edit"
          id={"edit-form-#{@file.index}"}
          class="flex-1"
        >
          <div class="form-control">
            <label class="label">
              <span class="label-text text-sm">Search for Metadata Match</span>
            </label>
            <div class="relative">
              <input
                type="text"
                name="edit_form[title]"
                value={@edit_form["title"]}
                class="input input-bordered input-sm w-full"
                phx-change="search_series"
                phx-debounce="300"
                autocomplete="off"
                placeholder="Search by title..."
              />
              <%= if @search_results != [] do %>
                <.search_results_dropdown_with_poster results={@search_results} />
              <% end %>
            </div>
          </div>
          <input type="hidden" name="edit_form[provider_id]" value={@edit_form["provider_id"]} />
          <input type="hidden" name="edit_form[type]" value={@edit_form["type"]} />
          <%= if @edit_form["type"] == "tv_show" do %>
            <div class="grid grid-cols-2 gap-2">
              <div class="form-control">
                <label class="label">
                  <span class="label-text text-xs">Season</span>
                </label>
                <input
                  type="number"
                  name="edit_form[season]"
                  value={@edit_form["season"]}
                  class="input input-bordered input-sm"
                  placeholder="1"
                  min="0"
                />
              </div>
              <div class="form-control">
                <label class="label">
                  <span class="label-text text-xs">Episode(s)</span>
                </label>
                <input
                  type="text"
                  name="edit_form[episodes]"
                  value={@edit_form["episodes"]}
                  class="input input-bordered input-sm"
                  placeholder="1, 2"
                />
              </div>
            </div>
          <% else %>
            <input type="hidden" name="edit_form[season]" value="" />
            <input type="hidden" name="edit_form[episodes]" value="" />
          <% end %>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-xs">Year</span>
            </label>
            <input
              type="number"
              name="edit_form[year]"
              value={@edit_form["year"]}
              class="input input-bordered input-sm"
              placeholder="2024"
              min="1900"
              max="2100"
            />
          </div>
          <div class="flex gap-2 justify-end">
            <button type="button" class="btn btn-ghost btn-sm" phx-click="cancel_edit">
              Cancel
            </button>
            <button
              type="submit"
              class="btn btn-primary btn-sm"
              disabled={@edit_form["provider_id"] == nil or @edit_form["provider_id"] == ""}
            >
              <.icon name="hero-check" class="w-4 h-4" /> Apply Match
            </button>
          </div>
        </.form>
      <% else %>
        <input type="checkbox" class="checkbox checkbox-primary checkbox-sm" disabled />
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-3">
            <div class="flex-1 min-w-0">
              <p class="font-semibold text-sm truncate text-error">
                {Path.basename(@file.file.path)}
              </p>
              <%= if parsed_info = Map.get(@file.file, :parsed_info) do %>
                <%= if parsed_info.type == :tv_show && parsed_info.title do %>
                  <p class="text-xs text-base-content/70 mt-1">
                    <span class="font-medium">Parsed as:</span>
                    {parsed_info.title}
                    <%= if parsed_info.season && parsed_info.episodes do %>
                      S{String.pad_leading(to_string(parsed_info.season), 2, "0")}E{String.pad_leading(
                        to_string(hd(parsed_info.episodes)),
                        2,
                        "0"
                      )}
                    <% end %>
                  </p>
                  <p class="text-xs text-warning">
                    Series or episode not found in database
                  </p>
                <% else %>
                  <%= if parsed_info.title do %>
                    <p class="text-xs text-base-content/70 mt-1">
                      <span class="font-medium">Parsed as:</span>
                      {parsed_info.title}
                      <%= if parsed_info.year do %>
                        ({parsed_info.year})
                      <% end %>
                    </p>
                    <p class="text-xs text-warning">Not found in database</p>
                  <% end %>
                <% end %>
              <% else %>
                <p class="text-xs text-base-content/60 truncate">
                  {@file.file.path}
                </p>
              <% end %>
              <p class="text-xs text-base-content/50">
                {format_file_size(@file.file.size)}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <div class="badge badge-xs badge-error">No Match</div>
              <button
                type="button"
                class="btn btn-xs btn-primary"
                phx-click="edit_file"
                phx-value-index={@file.index}
              >
                <.icon name="hero-magnifying-glass" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </li>
    """
  end

  @doc """
  Renders a type-filtered file as a compact list item.
  These are files that were filtered out due to library type mismatch
  (e.g., movies in a TV-only library).

  ## Attributes
    * `:file` - File data with `:file`, `:match_result`
    * `:library_type` - The type of the library being scanned (:series, :movies, :mixed)
  """
  attr :file, :map, required: true
  attr :library_type, :atom, default: nil

  def type_filtered_list_item(assigns) do
    ~H"""
    <li class="flex items-center gap-3 py-2 px-3 hover:bg-base-200/50 rounded-lg opacity-60">
      <div class="text-info mt-1">
        <.icon name="hero-funnel" class="w-4 h-4" />
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between gap-3">
          <div class="flex-1 min-w-0">
            <p class="font-medium text-sm truncate">
              {Path.basename(@file.file.path)}
            </p>
            <%= if @file.match_result do %>
              <p class="text-xs text-base-content/60 truncate">
                {type_mismatch_reason(@file.match_result, @library_type)}
              </p>
            <% end %>
            <p class="text-xs text-base-content/50">
              {format_file_size(@file.file.size)}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <%= if @file.match_result do %>
              <div class={"badge badge-xs " <> media_type_badge_class(@file.match_result.parsed_info.type)}>
                {media_type_label(@file.match_result.parsed_info.type)}
              </div>
            <% end %>
            <div class="badge badge-xs badge-info">Filtered</div>
          </div>
        </div>
      </div>
    </li>
    """
  end

  @doc """
  Renders a search results dropdown (compact version).

  ## Attributes
    * `:results` - List of search result maps
  """
  attr :results, :list, required: true

  def search_results_dropdown(assigns) do
    ~H"""
    <div class="absolute z-10 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-48 overflow-y-auto">
      <%= for result <- @results do %>
        <button
          type="button"
          class="w-full text-left px-3 py-2 hover:bg-base-200 border-b border-base-300 last:border-b-0"
          phx-click="select_search_result"
          phx-value-provider_id={result.provider_id}
          phx-value-title={result.title}
          phx-value-year={result.year || ""}
          phx-value-type={result.media_type}
        >
          <div class="font-medium text-sm">
            {result.title}
          </div>
          <div class="text-xs text-base-content/60">
            {result.year} • {String.upcase(to_string(result.media_type))}
          </div>
        </button>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a search results dropdown with poster images.

  ## Attributes
    * `:results` - List of search result maps
  """
  attr :results, :list, required: true

  def search_results_dropdown_with_poster(assigns) do
    ~H"""
    <div class="absolute z-10 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-64 overflow-y-auto">
      <%= for result <- @results do %>
        <button
          type="button"
          class="w-full text-left px-3 py-2 hover:bg-base-200 border-b border-base-300 last:border-b-0 flex gap-3"
          phx-click="select_search_result"
          phx-value-provider_id={result.provider_id}
          phx-value-title={result.title}
          phx-value-year={result.year || ""}
          phx-value-type={result.media_type}
        >
          <%= if result.poster_path do %>
            <img
              src={"https://image.tmdb.org/t/p/w92#{result.poster_path}"}
              alt={result.title}
              class="w-10 rounded"
            />
          <% end %>
          <div class="flex-1">
            <div class="font-medium text-sm">{result.title}</div>
            <div class="text-xs text-base-content/60">
              {result.year} • {String.upcase(to_string(result.media_type))}
            </div>
          </div>
        </button>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the import completion screen with results.

  ## Attributes
    * `:import_results` - Map with `:success`, `:failed`, `:skipped` counts
    * `:detailed_results` - List of detailed result maps
  """
  attr :import_results, :map, required: true
  attr :detailed_results, :list, required: true

  def import_complete_screen(assigns) do
    ~H"""
    <div class="mb-6">
      <%!-- Summary Stats with Header --%>
      <div class="stats stats-vertical sm:stats-horizontal shadow-md w-full mb-4 bg-base-100 border border-base-300">
        <div class="stat">
          <div class="stat-figure">
            <div class={if(@import_results.failed == 0, do: "text-success", else: "text-warning")}>
              <.icon
                name={
                  if(@import_results.failed == 0,
                    do: "hero-check-circle",
                    else: "hero-exclamation-triangle"
                  )
                }
                class="w-8 h-8"
              />
            </div>
          </div>
          <div class="stat-title text-xs">Total Processed</div>
          <div class="stat-value text-lg">
            {@import_results.success + @import_results.failed + @import_results.skipped}
          </div>
          <div class="stat-desc text-xs">Import complete</div>
        </div>
        <div class="stat">
          <div class="stat-title text-xs">Imported</div>
          <div class="stat-value text-lg text-success">{@import_results.success}</div>
          <div class="stat-desc text-xs">added to library</div>
        </div>
        <div class="stat">
          <div class="stat-title text-xs">Failed</div>
          <div class="stat-value text-lg text-error">{@import_results.failed}</div>
          <div class="stat-desc text-xs">with errors</div>
        </div>
        <%= if @import_results.skipped > 0 do %>
          <div class="stat">
            <div class="stat-title text-xs">Skipped</div>
            <div class="stat-value text-lg text-base-content/50">{@import_results.skipped}</div>
            <div class="stat-desc text-xs">items skipped</div>
          </div>
        <% end %>
      </div>

      <%!-- Action Buttons --%>
      <div class="flex items-center justify-between mb-4">
        <div class="flex gap-2">
          <%= if @import_results.failed > 0 do %>
            <button type="button" class="btn btn-warning btn-sm" phx-click="retry_all_failed">
              <.icon name="hero-arrow-path" class="w-4 h-4" /> Retry All Failed
            </button>
          <% end %>
          <button type="button" class="btn btn-ghost btn-sm" phx-click="export_results">
            <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> Export Details
          </button>
        </div>
        <div class="flex gap-2">
          <button type="button" class="btn btn-outline btn-sm" phx-click="start_over">
            <.icon name="hero-arrow-path" class="w-4 h-4" /> Import More Files
          </button>
          <button type="button" class="btn btn-primary btn-sm" phx-click="cancel">
            <.icon name="hero-check" class="w-4 h-4" /> Done
          </button>
        </div>
      </div>

      <%!-- Detailed Results --%>
      <%= if @import_results.success > 0 do %>
        <div class="mb-6">
          <h3 class="text-lg font-semibold mb-3 flex items-center gap-2">
            <.icon name="hero-check-circle" class="w-6 h-6 text-success" />
            Successfully Imported ({@import_results.success})
          </h3>
          <div class="space-y-2">
            <%= for {result, _idx} <- Enum.with_index(@detailed_results) do %>
              <%= if result.status == :success do %>
                <div class="card bg-base-100 shadow-sm border border-success/20">
                  <div class="card-body p-4">
                    <div class="flex items-start gap-3">
                      <div class="text-success mt-1">
                        <.icon name="hero-check-circle" class="w-5 h-5" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="font-semibold text-sm">{result.file_name}</p>
                        <p class="text-xs text-base-content/60 truncate">{result.file_path}</p>
                        <%= if result.action_taken do %>
                          <p class="text-xs text-success mt-1">{result.action_taken}</p>
                        <% end %>
                      </div>
                      <div class="badge badge-success badge-sm">Success</div>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @import_results.failed > 0 do %>
        <div class="mb-6">
          <h3 class="text-lg font-semibold mb-3 flex items-center gap-2">
            <.icon name="hero-x-circle" class="w-6 h-6 text-error" />
            Failed ({@import_results.failed})
          </h3>
          <div class="space-y-2">
            <%= for {result, idx} <- Enum.with_index(@detailed_results) do %>
              <%= if result.status == :failed do %>
                <div class="card bg-base-100 shadow-sm border border-error/20">
                  <div class="card-body p-4">
                    <div class="flex items-start gap-3">
                      <div class="text-error mt-1">
                        <.icon name="hero-x-circle" class="w-5 h-5" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="font-semibold text-sm">{result.file_name}</p>
                        <p class="text-xs text-base-content/60 truncate">{result.file_path}</p>
                        <%= if result.error_message do %>
                          <div class="alert alert-error mt-2 py-2 px-3">
                            <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                            <span class="text-xs">{result.error_message}</span>
                          </div>
                        <% end %>
                      </div>
                      <div class="flex flex-col gap-2">
                        <div class="badge badge-error badge-sm">Failed</div>
                        <button
                          type="button"
                          class="btn btn-xs btn-warning"
                          phx-click="retry_failed_item"
                          phx-value-index={idx}
                        >
                          <.icon name="hero-arrow-path" class="w-3 h-3" /> Retry
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @import_results.skipped > 0 do %>
        <div class="mb-6">
          <h3 class="text-lg font-semibold mb-3 flex items-center gap-2">
            <.icon name="hero-arrow-path" class="w-6 h-6 text-base-content/50" />
            Skipped ({@import_results.skipped})
          </h3>
          <div class="space-y-2">
            <%= for {result, _idx} <- Enum.with_index(@detailed_results) do %>
              <%= if result.status == :skipped do %>
                <div class="card bg-base-100 shadow-sm border border-base-content/10">
                  <div class="card-body p-4">
                    <div class="flex items-start gap-3">
                      <div class="text-base-content/50 mt-1">
                        <.icon name="hero-arrow-path" class="w-5 h-5" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="font-semibold text-sm">{result.file_name}</p>
                        <p class="text-xs text-base-content/60 truncate">{result.file_path}</p>
                        <%= if result.error_message do %>
                          <p class="text-xs text-base-content/50 mt-1">
                            {result.error_message}
                          </p>
                        <% end %>
                      </div>
                      <div class="badge badge-ghost badge-sm">Skipped</div>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  ## Helper Functions

  defp format_file_size(size) when size < 1024, do: "#{size} B"
  defp format_file_size(size) when size < 1_048_576, do: "#{Float.round(size / 1024, 1)} KB"

  defp format_file_size(size) when size < 1_073_741_824,
    do: "#{Float.round(size / 1_048_576, 1)} MB"

  defp format_file_size(size), do: "#{Float.round(size / 1_073_741_824, 1)} GB"

  defp confidence_badge_class(confidence) when confidence >= 0.8, do: "badge-success"
  defp confidence_badge_class(confidence) when confidence >= 0.5, do: "badge-warning"
  defp confidence_badge_class(_), do: "badge-error"

  defp confidence_label(confidence) when confidence >= 0.8, do: "High"
  defp confidence_label(confidence) when confidence >= 0.5, do: "Medium"
  defp confidence_label(_), do: "Low"

  defp media_type_badge_class(:movie), do: "badge-accent"
  defp media_type_badge_class(:tv_show), do: "badge-info"
  defp media_type_badge_class(_), do: "badge-ghost"

  defp media_type_label(:movie), do: "Movie"
  defp media_type_label(:tv_show), do: "TV Show"
  defp media_type_label(_), do: "Unknown"

  defp type_mismatch_reason(match_result, :series) when match_result.parsed_info.type == :movie do
    "Movie detected in TV series library: \"#{match_result.title}\""
  end

  defp type_mismatch_reason(match_result, :movies)
       when match_result.parsed_info.type == :tv_show do
    "TV show detected in movies library: \"#{match_result.title}\""
  end

  defp type_mismatch_reason(match_result, _library_type) do
    "Type mismatch: \"#{match_result.title}\" (#{media_type_label(match_result.parsed_info.type)})"
  end
end
