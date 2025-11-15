defmodule MydiaWeb.MediaLive.Show.Modals do
  @moduledoc """
  Modal components for the MediaLive.Show page.
  """
  use Phoenix.Component
  import MydiaWeb.CoreComponents

  # Import the formatting and search helper functions
  import MydiaWeb.MediaLive.Show.Formatters
  import MydiaWeb.MediaLive.Show.SearchHelpers

  @doc """
  Delete confirmation modal for removing media item from library.
  Allows user to choose whether to delete files from disk.
  """
  attr :media_item, :map, required: true
  attr :delete_files, :boolean, required: true

  def delete_confirm_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-lg">
        <h3 class="font-bold text-lg mb-4">Delete {@media_item.title}?</h3>

        <form phx-change="toggle_delete_files">
          <div class="space-y-2.5 mb-5">
            <label class={[
              "flex items-start gap-3 p-3.5 rounded-lg border-2 cursor-pointer transition-all hover:shadow-sm",
              !@delete_files && "border-primary bg-primary/10",
              @delete_files && "border-base-300 hover:border-primary/50"
            ]}>
              <input
                type="radio"
                name="delete_files"
                value="false"
                class="radio radio-primary mt-0.5 flex-shrink-0"
                checked={!@delete_files}
              />
              <div>
                <div class="font-medium mb-1">Remove from library only</div>
                <div class="text-sm opacity-75">Files stay on disk, can be re-imported later</div>
              </div>
            </label>

            <label class={[
              "flex items-start gap-3 p-3.5 rounded-lg border-2 cursor-pointer transition-all hover:shadow-sm",
              @delete_files && "border-error bg-error/10",
              !@delete_files && "border-base-300 hover:border-error/50"
            ]}>
              <input
                type="radio"
                name="delete_files"
                value="true"
                class="radio radio-error mt-0.5 flex-shrink-0"
                checked={@delete_files}
              />
              <div>
                <div class="font-medium mb-1">Delete files from disk</div>
                <div class="text-sm opacity-75 flex items-center gap-1">
                  <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                  <span>Permanently deletes all files - cannot be undone</span>
                </div>
              </div>
            </label>
          </div>
        </form>

        <div class="modal-action">
          <button type="button" phx-click="hide_delete_confirm" class="btn btn-ghost">
            Cancel
          </button>
          <button
            type="button"
            phx-click="delete_media"
            class={["btn", (@delete_files && "btn-error") || "btn-warning"]}
          >
            <.icon name="hero-trash" class="w-4 h-4" />
            {if @delete_files, do: "Delete Everything", else: "Remove from Library"}
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_delete_confirm"></div>
    </div>
    """
  end

  @doc """
  Edit modal for updating media item settings (quality profile, monitored status).
  """
  attr :media_item, :map, required: true
  attr :edit_form, :map, required: true
  attr :quality_profiles, :list, required: true

  def edit_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Edit {@media_item.title}</h3>

        <.form
          for={@edit_form}
          id="edit-media-form"
          phx-change="validate_edit"
          phx-submit="save_edit"
        >
          <%!-- Quality Profile Selection --%>
          <div class="form-control mb-4">
            <label class="label">
              <span class="label-text font-medium">Quality Profile</span>
            </label>
            <.input
              field={@edit_form[:quality_profile_id]}
              type="select"
              options={[{"No Profile", nil}] ++ Enum.map(@quality_profiles, &{&1.name, &1.id})}
              prompt="Select a quality profile"
            />
            <label class="label">
              <span class="label-text-alt">
                Controls which video qualities are preferred for downloads
              </span>
            </label>
          </div>

          <%!-- Monitored Toggle --%>
          <div class="form-control mb-6">
            <label class="label cursor-pointer justify-start gap-4">
              <.input field={@edit_form[:monitored]} type="checkbox" class="checkbox" />
              <div>
                <span class="label-text font-medium">Monitored</span>
                <p class="label-text-alt mt-1">
                  Automatically search for and download new content
                </p>
              </div>
            </label>
          </div>

          <div class="modal-action">
            <button type="button" phx-click="hide_edit_modal" class="btn btn-ghost">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              Save Changes
            </button>
          </div>
        </.form>
      </div>
      <div class="modal-backdrop" phx-click="hide_edit_modal"></div>
    </div>
    """
  end

  @doc """
  File delete confirmation modal for removing a media file record.
  """
  attr :file_to_delete, :map, required: true

  def file_delete_confirm_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Delete Media File?</h3>
        <p class="py-4">
          Are you sure you want to delete this file?
        </p>
        <div class="bg-base-200 p-3 rounded-box mb-4">
          <p class="text-sm font-mono text-base-content/70">
            {Mydia.Library.MediaFile.absolute_path(@file_to_delete)}
          </p>
          <p class="text-sm mt-2">
            <span class="font-semibold">Size:</span>
            {format_file_size(@file_to_delete.size)}
          </p>
        </div>
        <p class="text-warning text-sm mb-4">
          <.icon name="hero-exclamation-triangle" class="w-4 h-4 inline" />
          This will only remove the database record. The actual file will remain on disk.
        </p>
        <div class="modal-action">
          <button type="button" phx-click="hide_file_delete_confirm" class="btn btn-ghost">
            Cancel
          </button>
          <button type="button" phx-click="delete_media_file" class="btn btn-error">
            Delete Record
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_file_delete_confirm"></div>
    </div>
    """
  end

  @doc """
  File details modal showing comprehensive information about a media file.
  """
  attr :file_details, :map, required: true

  def file_details_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">Media File Details</h3>

        <div class="space-y-4">
          <%!-- File Path --%>
          <div>
            <h4 class="text-sm font-semibold text-base-content/70 mb-2">File Path</h4>
            <p class="text-sm font-mono bg-base-200 p-3 rounded-box break-all">
              {Mydia.Library.MediaFile.absolute_path(@file_details)}
            </p>
          </div>
          <%!-- Quality Information --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Resolution</h4>
              <p class="text-sm">
                <%= if @file_details.resolution do %>
                  <span class="badge badge-primary">{@file_details.resolution}</span>
                <% else %>
                  <span class="text-base-content/50">Unknown</span>
                <% end %>
              </p>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Size</h4>
              <p class="text-sm">{format_file_size(@file_details.size)}</p>
            </div>
          </div>
          <%!-- Codec Information --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Video Codec</h4>
              <p class="text-sm">{@file_details.codec || "Unknown"}</p>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Audio Codec</h4>
              <p class="text-sm">{@file_details.audio_codec || "Unknown"}</p>
            </div>
          </div>
          <%!-- Additional Information --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">HDR Format</h4>
              <p class="text-sm">
                <%= if @file_details.hdr_format do %>
                  <span class="badge badge-accent">{@file_details.hdr_format}</span>
                <% else %>
                  <span class="text-base-content/50">None</span>
                <% end %>
              </p>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Bitrate</h4>
              <p class="text-sm">
                <%= if @file_details.bitrate do %>
                  {Float.round(@file_details.bitrate / 1_000_000, 2)} Mbps
                <% else %>
                  <span class="text-base-content/50">Unknown</span>
                <% end %>
              </p>
            </div>
          </div>
          <%!-- Verification Status --%>
          <div>
            <h4 class="text-sm font-semibold text-base-content/70 mb-2">Verification Status</h4>
            <p class="text-sm">
              <%= if @file_details.verified_at do %>
                <span class="text-success">
                  <.icon name="hero-check-circle" class="w-4 h-4 inline" />
                  Verified on {Calendar.strftime(
                    @file_details.verified_at,
                    "%b %d, %Y at %I:%M %p"
                  )}
                </span>
              <% else %>
                <span class="text-warning">
                  <.icon name="hero-exclamation-triangle" class="w-4 h-4 inline" /> Not verified
                </span>
              <% end %>
            </p>
          </div>
          <%!-- Metadata (if present) --%>
          <%= if @file_details.metadata && map_size(@file_details.metadata) > 0 do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Additional Metadata</h4>
              <pre class="text-xs bg-base-200 p-3 rounded-box overflow-x-auto"><%= Jason.encode!(@file_details.metadata, pretty: true) %></pre>
            </div>
          <% end %>
        </div>

        <div class="modal-action">
          <button type="button" phx-click="hide_file_details" class="btn btn-ghost">
            Close
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_file_details"></div>
    </div>
    """
  end

  @doc """
  Download cancel confirmation modal.
  """
  attr :download_to_cancel, :map, required: true

  def download_cancel_confirm_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Cancel Download?</h3>
        <p class="py-4">
          Are you sure you want to cancel this download?
        </p>
        <div class="bg-base-200 p-3 rounded-box mb-4">
          <p class="text-sm font-medium">{@download_to_cancel.title}</p>
          <%= if quality = @download_to_cancel.metadata["quality"] do %>
            <p class="text-sm text-base-content/70 mt-1">
              Quality: <span class="badge badge-sm">{format_download_quality(quality)}</span>
            </p>
          <% end %>
          <%= if @download_to_cancel.progress do %>
            <p class="text-sm text-base-content/70 mt-1">
              Progress: {@download_to_cancel.progress}%
            </p>
          <% end %>
        </div>
        <p class="text-warning text-sm mb-4">
          <.icon name="hero-exclamation-triangle" class="w-4 h-4 inline" />
          The download will be stopped and marked as cancelled.
        </p>
        <div class="modal-action">
          <button type="button" phx-click="hide_download_cancel_confirm" class="btn btn-ghost">
            Keep Downloading
          </button>
          <button type="button" phx-click="cancel_download" class="btn btn-warning">
            Cancel Download
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_download_cancel_confirm"></div>
    </div>
    """
  end

  @doc """
  Download delete confirmation modal for removing a download record.
  """
  attr :download_to_delete, :map, required: true

  def download_delete_confirm_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Remove Download?</h3>
        <p class="py-4">
          Are you sure you want to remove this download from history?
        </p>
        <div class="bg-base-200 p-3 rounded-box mb-4">
          <p class="text-sm font-medium">{@download_to_delete.title}</p>
          <p class="text-sm text-base-content/70 mt-1">
            Status:
            <span class={[
              "badge badge-sm",
              @download_to_delete.status == "completed" && "badge-success",
              @download_to_delete.status == "failed" && "badge-error",
              @download_to_delete.status == "downloading" && "badge-info",
              @download_to_delete.status == "pending" && "badge-warning"
            ]}>
              {format_download_status(@download_to_delete.status)}
            </span>
          </p>
        </div>
        <p class="text-warning text-sm mb-4">
          <.icon name="hero-exclamation-triangle" class="w-4 h-4 inline" />
          This will only remove the download record. Downloaded files will remain on disk.
        </p>
        <div class="modal-action">
          <button
            type="button"
            phx-click="hide_download_delete_confirm"
            class="btn btn-ghost"
          >
            Cancel
          </button>
          <button type="button" phx-click="delete_download_record" class="btn btn-error">
            Remove Record
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_download_delete_confirm"></div>
    </div>
    """
  end

  @doc """
  Download details modal showing comprehensive information about a download.
  """
  attr :download_details, :map, required: true

  def download_details_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">Download Details</h3>

        <div class="space-y-4">
          <%!-- Title and Status --%>
          <div>
            <h4 class="text-sm font-semibold text-base-content/70 mb-2">Title</h4>
            <p class="text-sm font-medium">{@download_details.title}</p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Status</h4>
              <span class={[
                "badge",
                @download_details.status == "completed" && "badge-success",
                @download_details.status == "failed" && "badge-error",
                @download_details.status == "downloading" && "badge-info",
                @download_details.status == "pending" && "badge-warning"
              ]}>
                {format_download_status(@download_details.status)}
              </span>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Quality</h4>
              <%= if quality = @download_details.metadata["quality"] do %>
                <span class="badge">{format_download_quality(quality)}</span>
              <% else %>
                <span class="text-base-content/50">Unknown</span>
              <% end %>
            </div>
          </div>
          <%!-- Progress --%>
          <%= if @download_details.progress do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Progress</h4>
              <div class="flex items-center gap-3">
                <progress
                  class="progress progress-primary flex-1"
                  value={@download_details.progress}
                  max="100"
                >
                </progress>
                <span class="text-sm font-mono">{@download_details.progress}%</span>
              </div>
            </div>
          <% end %>
          <%!-- Source URL --%>
          <%= if @download_details.source_url do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Source URL</h4>
              <p class="text-xs font-mono bg-base-200 p-3 rounded-box break-all">
                {@download_details.source_url}
              </p>
            </div>
          <% end %>
          <%!-- Error Message --%>
          <%= if @download_details.error_message do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Error Message</h4>
              <div class="alert alert-error">
                <.icon name="hero-exclamation-circle" class="w-5 h-5" />
                <span class="text-sm">{@download_details.error_message}</span>
              </div>
            </div>
          <% end %>
          <%!-- Timestamps --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">Added</h4>
              <p class="text-sm">
                {Calendar.strftime(@download_details.inserted_at, "%b %d, %Y at %I:%M %p")}
              </p>
            </div>
            <%= if @download_details.completed_at do %>
              <div>
                <h4 class="text-sm font-semibold text-base-content/70 mb-2">Completed</h4>
                <p class="text-sm">
                  {Calendar.strftime(@download_details.completed_at, "%b %d, %Y at %I:%M %p")}
                </p>
              </div>
            <% end %>
          </div>
          <%!-- Estimated Completion --%>
          <%= if @download_details.estimated_completion do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">
                Estimated Completion
              </h4>
              <p class="text-sm">
                {Calendar.strftime(
                  @download_details.estimated_completion,
                  "%b %d, %Y at %I:%M %p"
                )}
              </p>
            </div>
          <% end %>
          <%!-- Metadata (if present) --%>
          <%= if @download_details.metadata && map_size(@download_details.metadata) > 0 do %>
            <div>
              <h4 class="text-sm font-semibold text-base-content/70 mb-2">
                Additional Metadata
              </h4>
              <pre class="text-xs bg-base-200 p-3 rounded-box overflow-x-auto"><%= Jason.encode!(@download_details.metadata, pretty: true) %></pre>
            </div>
          <% end %>
        </div>

        <div class="modal-action">
          <button type="button" phx-click="hide_download_details" class="btn btn-ghost">
            Close
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_download_details"></div>
    </div>
    """
  end

  @doc """
  Manual search modal for searching and downloading content manually.
  Large modal with search results, filters, and sorting.
  """
  attr :manual_search_context, :map, default: nil
  attr :media_item, :map, required: true
  attr :manual_search_query, :string, required: true
  attr :searching, :boolean, required: true
  attr :results_empty?, :boolean, required: true
  attr :streams, :map, required: true
  attr :quality_filter, :string, default: nil
  attr :min_seeders, :integer, default: 0
  attr :sort_by, :atom, required: true

  def manual_search_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-7xl h-[90vh] flex flex-col p-0">
        <%!-- Modal Header --%>
        <div class="sticky top-0 z-10 bg-base-100 border-b border-base-300 p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-2xl font-bold">
              Manual Search
              <%= if @manual_search_context do %>
                <%= case @manual_search_context.type do %>
                  <% :episode -> %>
                    <span class="text-base text-base-content/70">for Episode</span>
                  <% :season -> %>
                    <span class="text-base text-base-content/70">
                      for {@media_item.title} - Season {@manual_search_context.season_number}
                    </span>
                  <% :media_item -> %>
                    <span class="text-base text-base-content/70">
                      for {@media_item.title}
                    </span>
                  <% _ -> %>
                    <span></span>
                <% end %>
              <% end %>
            </h3>
            <button
              type="button"
              phx-click="close_manual_search_modal"
              class="btn btn-ghost btn-sm btn-circle"
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>
          <%!-- Search Query Display --%>
          <div class="flex items-center gap-2 text-sm">
            <.icon name="hero-magnifying-glass" class="w-5 h-5 text-base-content/60" />
            <span class="text-base-content/70">Searching for:</span>
            <span class="font-semibold">{@manual_search_query}</span>
          </div>
        </div>
        <%!-- Modal Body --%>
        <div class="flex-1 overflow-y-auto p-6">
          <%!-- Filters and Sort --%>
          <%= if !@searching do %>
            <div class="flex flex-col lg:flex-row gap-4 mb-6">
              <%!-- Filters --%>
              <div class="card bg-base-200 shadow flex-1">
                <div class="card-body p-4">
                  <h4 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-funnel" class="w-5 h-5" /> Filters
                  </h4>
                  <form phx-change="filter_search" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <%!-- Quality filter --%>
                    <div class="form-control">
                      <label class="label label-text text-xs">Quality</label>
                      <select name="quality" class="select select-bordered select-sm">
                        <option value="" selected={is_nil(@quality_filter)}>All</option>
                        <option value="720p" selected={@quality_filter == "720p"}>720p</option>
                        <option value="1080p" selected={@quality_filter == "1080p"}>1080p</option>
                        <option value="2160p" selected={@quality_filter in ["2160p", "4k"]}>
                          4K (2160p)
                        </option>
                      </select>
                    </div>
                    <%!-- Min seeders filter --%>
                    <div class="form-control">
                      <label class="label label-text text-xs">Min Seeders</label>
                      <input
                        type="number"
                        name="min_seeders"
                        value={@min_seeders}
                        min="0"
                        class="input input-bordered input-sm"
                        placeholder="0"
                      />
                    </div>
                  </form>
                </div>
              </div>
              <%!-- Sort options --%>
              <div class="card bg-base-200 shadow lg:w-64">
                <div class="card-body p-4">
                  <h4 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-arrows-up-down" class="w-5 h-5" /> Sort By
                  </h4>
                  <form phx-change="sort_search">
                    <select name="sort_by" class="select select-bordered select-sm w-full">
                      <option value="quality" selected={@sort_by == :quality}>
                        Quality (Best First)
                      </option>
                      <option value="seeders" selected={@sort_by == :seeders}>
                        Seeders (Most First)
                      </option>
                      <option value="size" selected={@sort_by == :size}>
                        Size (Largest First)
                      </option>
                      <option value="date" selected={@sort_by == :date}>
                        Date (Newest First)
                      </option>
                    </select>
                  </form>
                </div>
              </div>
            </div>
          <% end %>
          <%!-- Loading State --%>
          <%= if @searching do %>
            <div class="flex flex-col items-center justify-center py-16">
              <span class="loading loading-spinner loading-lg text-primary mb-4"></span>
              <h3 class="text-xl font-semibold text-base-content/70 mb-2">
                Searching across indexers...
              </h3>
              <p class="text-base-content/50">
                This may take a few seconds
              </p>
            </div>
          <% end %>
          <%!-- Empty State (no results) --%>
          <%= if @results_empty? && !@searching do %>
            <div class="flex flex-col items-center justify-center py-16 text-center">
              <.icon name="hero-exclamation-circle" class="w-20 h-20 text-base-content/20 mb-6" />
              <h3 class="text-2xl font-semibold text-base-content/70 mb-3">
                No Results Found
              </h3>
              <p class="text-base-content/50 max-w-md mb-4">
                We couldn't find any releases matching
                "<span class="font-semibold">{@manual_search_query}</span>"
              </p>
              <div class="text-sm text-base-content/60">
                <p>Try:</p>
                <ul class="list-disc list-inside mt-2 space-y-1">
                  <li>Using different keywords or spelling</li>
                  <li>Removing or adjusting filters</li>
                  <li>Checking that your indexers are configured and enabled</li>
                </ul>
              </div>
            </div>
          <% end %>
          <%!-- Results Table --%>
          <%= if !@searching && !@results_empty? do %>
            <div class="overflow-x-auto">
              <table
                id="manual-search-results"
                phx-update="stream"
                class="table table-zebra w-full bg-base-100 shadow-lg"
              >
                <thead>
                  <tr class="bg-base-300">
                    <th class="w-2/5">Release Title</th>
                    <th class="w-1/6">Quality & Size</th>
                    <th class="w-1/6 hidden md:table-cell">Health</th>
                    <th class="w-1/6 hidden lg:table-cell">Source</th>
                    <th class="w-32">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    :for={{id, result} <- @streams.search_results}
                    id={id}
                    class="hover cursor-pointer"
                  >
                    <%!-- Title Column --%>
                    <td>
                      <div class="flex flex-col">
                        <div class="font-semibold text-sm line-clamp-2" title={result.title}>
                          {result.title}
                        </div>
                        <%!-- Mobile-only compact info --%>
                        <div class="flex gap-2 mt-2 md:hidden flex-wrap">
                          <span class="badge badge-ghost badge-sm">
                            <.icon name="hero-arrow-up" class="w-3 h-3 mr-1" /> {result.seeders}
                            <span class="mx-1 text-base-content/30">/</span>
                            <.icon name="hero-arrow-down" class="w-3 h-3 mr-1" /> {result.leechers}
                          </span>
                          <span class="badge badge-outline badge-sm">{result.indexer}</span>
                        </div>
                      </div>
                    </td>
                    <%!-- Quality & Size Column --%>
                    <td>
                      <div class="flex flex-col gap-1">
                        <span class="badge badge-primary badge-sm">
                          {get_search_quality_badge(result)}
                        </span>
                        <span class="text-xs font-mono text-base-content/70">
                          {format_search_size(result)}
                        </span>
                      </div>
                    </td>
                    <%!-- Health Column (Seeders/Peers with indicator) --%>
                    <td class="hidden md:table-cell">
                      <div class="flex items-center gap-3">
                        <%!-- Health indicator --%>
                        <div
                          class="radial-progress text-xs"
                          style={"--value:#{trunc(search_health_score(result) * 100)}; --size:2.5rem;"}
                          role="progressbar"
                        >
                          {trunc(search_health_score(result) * 100)}%
                        </div>
                        <%!-- Seeders/Peers --%>
                        <div class="flex flex-col text-xs">
                          <div class="flex items-center gap-1">
                            <.icon name="hero-arrow-up" class="w-3 h-3 text-success" />
                            <span class="font-semibold text-success">{result.seeders}</span>
                          </div>
                          <div class="flex items-center gap-1">
                            <.icon name="hero-arrow-down" class="w-3 h-3 text-info" />
                            <span class="text-base-content/70">{result.leechers}</span>
                          </div>
                        </div>
                      </div>
                    </td>
                    <%!-- Source Column (Indexer + Date) --%>
                    <td class="hidden lg:table-cell">
                      <div class="flex flex-col gap-1">
                        <span class="badge badge-outline badge-sm">{result.indexer}</span>
                        <span class="text-xs text-base-content/60">
                          {format_search_date(result.published_at)}
                        </span>
                      </div>
                    </td>
                    <%!-- Actions Column --%>
                    <td>
                      <button
                        class="btn btn-primary btn-sm"
                        phx-click="download_from_search"
                        phx-value-download-url={result.download_url}
                        phx-value-title={result.title}
                        phx-value-indexer={result.indexer}
                        phx-value-size={result.size || 0}
                        phx-value-seeders={result.seeders || 0}
                        phx-value-leechers={result.leechers || 0}
                        phx-value-quality={get_search_quality_badge(result) || "Unknown"}
                        title="Download this release"
                      >
                        <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> Download
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="close_manual_search_modal"></div>
    </div>
    """
  end

  @doc """
  Rename files modal showing preview of current and proposed filenames.
  """
  attr :rename_previews, :list, required: true
  attr :renaming_files, :boolean, required: true

  def rename_files_modal(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-4xl max-h-[85vh] flex flex-col p-0">
        <%!-- Modal Header --%>
        <div class="sticky top-0 z-10 bg-base-100 border-b border-base-300 px-4 py-3">
          <div class="flex items-center justify-between gap-4">
            <h3 class="text-lg font-bold">Rename Files</h3>
            <button
              type="button"
              phx-click="hide_rename_modal"
              class="btn btn-ghost btn-xs btn-circle"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>
        </div>
        <%!-- Modal Body --%>
        <div class="flex-1 overflow-y-auto p-3">
          <%= if Enum.empty?(@rename_previews) do %>
            <div class="flex flex-col items-center justify-center py-12 text-center">
              <.icon name="hero-exclamation-circle" class="w-12 h-12 text-base-content/20 mb-3" />
              <h3 class="text-lg font-semibold text-base-content/70 mb-1">No Files to Rename</h3>
              <p class="text-sm text-base-content/50">
                There are no media files to rename.
              </p>
            </div>
          <% else %>
            <div class="space-y-2">
              <%= for preview <- @rename_previews do %>
                <div class="border border-base-300 rounded-lg p-2 bg-base-100">
                  <%!-- Current → Proposed in compact format --%>
                  <div class="flex items-center gap-2 text-xs">
                    <%= if preview.current_filename != preview.proposed_filename do %>
                      <span class="badge badge-primary badge-xs">Rename</span>
                    <% else %>
                      <span class="badge badge-ghost badge-xs">Same</span>
                    <% end %>
                    <div class="flex-1 min-w-0">
                      <div
                        class="font-mono text-base-content/60 truncate"
                        title={preview.current_filename}
                      >
                        {preview.current_filename}
                      </div>
                      <div class="flex items-center gap-1 mt-0.5">
                        <.icon name="hero-arrow-right" class="w-3 h-3 text-primary flex-shrink-0" />
                        <div
                          class="font-mono text-primary font-medium truncate"
                          title={preview.proposed_filename}
                        >
                          {preview.proposed_filename}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        <%!-- Modal Footer --%>
        <div class="sticky bottom-0 bg-base-100 border-t border-base-300 px-4 py-2">
          <%= if !Enum.empty?(@rename_previews) do %>
            <div class="flex items-center justify-between gap-3">
              <div class="text-xs text-base-content/70">
                {Enum.count(@rename_previews, fn p ->
                  p.current_filename != p.proposed_filename
                end)} of {length(@rename_previews)} will be renamed
              </div>
              <div class="flex gap-2">
                <button
                  type="button"
                  phx-click="hide_rename_modal"
                  class="btn btn-ghost btn-sm"
                  disabled={@renaming_files}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  phx-click="confirm_rename_files"
                  class="btn btn-primary btn-sm"
                  disabled={@renaming_files}
                >
                  <%= if @renaming_files do %>
                    <span class="loading loading-spinner loading-xs"></span> Renaming...
                  <% else %>
                    <.icon name="hero-check" class="w-4 h-4" /> Rename
                  <% end %>
                </button>
              </div>
            </div>
          <% else %>
            <button type="button" phx-click="hide_rename_modal" class="btn btn-ghost btn-sm">
              Close
            </button>
          <% end %>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="hide_rename_modal"></div>
    </div>
    """
  end
end
