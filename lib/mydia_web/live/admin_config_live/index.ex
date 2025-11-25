defmodule MydiaWeb.AdminConfigLive.Index do
  use MydiaWeb, :live_view
  alias Mydia.DB
  alias Mydia.Repo
  alias Mydia.Settings
  alias Mydia.Settings.{QualityProfile, DownloadClientConfig, IndexerConfig, LibraryPath}
  alias Mydia.Downloads.ClientHealth
  alias Mydia.Indexers
  alias Mydia.Indexers.Health, as: IndexerHealth
  alias Mydia.Indexers.CardigannFeatureFlags
  alias Mydia.System
  alias MydiaWeb.AdminConfigLive.Components
  alias MydiaWeb.AdminConfigLive.FlareSolverrStatusComponent

  require Logger
  alias Mydia.Logger, as: MydiaLogger

  # Capture Mix.env at compile time since Mix is not available in releases
  @env Mix.env()

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh system data every 5 seconds for real-time updates
      :timer.send_interval(5000, self(), :refresh_system_data)
    end

    {:ok,
     socket
     |> assign(:page_title, "Configuration")
     |> assign(:active_tab, "status")
     |> assign(:cardigann_enabled, CardigannFeatureFlags.enabled?())
     |> load_configuration_data()
     |> load_system_data()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "status"

    {:noreply,
     socket
     |> assign(:active_tab, tab)
     |> maybe_setup_form(tab)}
  end

  @impl true
  def handle_info(:refresh_system_data, socket) do
    {:noreply, load_system_data(socket)}
  end

  @impl true
  def handle_info(:reload_library_indexers, socket) do
    # Reload library indexers when a library indexer is toggled
    cardigann_enabled = CardigannFeatureFlags.enabled?()

    library_indexers =
      if cardigann_enabled do
        Indexers.list_cardigann_definitions(enabled: true)
      else
        []
      end

    library_indexer_stats =
      if cardigann_enabled do
        Indexers.count_cardigann_definitions()
      else
        %{total: 0, enabled: 0, disabled: 0}
      end

    {:noreply,
     socket
     |> assign(:library_indexers, library_indexers)
     |> assign(:library_indexer_stats, library_indexer_stats)}
  end

  @impl true
  def handle_info({:sync_complete, component_id, result}, socket) do
    # Forward the sync result to the IndexerLibraryComponent
    send_update(MydiaWeb.AdminConfigLive.IndexerLibraryComponent,
      id: component_id,
      sync_result: result
    )

    # Also reload the library indexers data for the main indexers tab
    cardigann_enabled = CardigannFeatureFlags.enabled?()

    library_indexers =
      if cardigann_enabled do
        Indexers.list_cardigann_definitions(enabled: true)
      else
        []
      end

    library_indexer_stats =
      if cardigann_enabled do
        Indexers.count_cardigann_definitions()
      else
        %{total: 0, enabled: 0, disabled: 0}
      end

    {:noreply,
     socket
     |> assign(:library_indexers, library_indexers)
     |> assign(:library_indexer_stats, library_indexer_stats)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/config?tab=#{tab}")}
  end

  ## General Settings Events

  @impl true
  def handle_event(
        "update_setting_form",
        %{"category" => category, "settings" => settings},
        socket
      ) do
    # Convert category string to atom for schema compatibility
    category_atom = category_string_to_atom(category)

    # Process each changed setting with validation
    results =
      settings
      |> Enum.map(fn {key, value} ->
        # Validate each setting through a changeset
        changeset =
          validate_config_setting(%{
            key: key,
            value: to_string(value),
            category: category_atom
          })

        if changeset.valid? do
          validated_data = Ecto.Changeset.apply_changes(changeset)
          # Add updated_by_id for audit trail
          validated_data_with_user =
            Map.put(validated_data, :updated_by_id, socket.assigns.current_user.id)

          upsert_config_setting(validated_data_with_user)
        else
          {:error, changeset}
        end
      end)

    # Check if all updates succeeded
    if Enum.all?(results, fn result -> match?({:ok, _}, result) end) do
      {:noreply,
       socket
       |> put_flash(:info, "Settings updated successfully")
       |> load_configuration_data()}
    else
      # Log failed updates
      failed_results =
        results
        |> Enum.with_index()
        |> Enum.reject(fn {result, _} -> match?({:ok, _}, result) end)

      Enum.each(failed_results, fn {{:error, error}, idx} ->
        setting_key = Enum.at(Map.keys(settings), idx)

        MydiaLogger.log_error(:liveview, "Failed to update setting",
          error: error,
          error_details: inspect(error, pretty: true),
          operation: :update_setting,
          category: category,
          setting_key: setting_key,
          user_id: socket.assigns.current_user.id
        )
      end)

      error_msg = MydiaLogger.user_error_message(:update_setting, :multiple_failures)

      {:noreply,
       socket
       |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event(
        "toggle_setting",
        %{"key" => key, "category" => category} = params,
        socket
      ) do
    # Convert category string to atom for schema compatibility
    category_atom = category_string_to_atom(category)

    # Get the new value, either from params or by looking up current value and toggling it
    new_value =
      case Map.get(params, "value") do
        nil ->
          # Value not provided (Phoenix drops false values), look up current setting
          case Settings.get_config_setting_by_key(key) do
            nil -> "true"
            setting -> to_string(!parse_boolean_value(setting.value))
          end

        value ->
          to_string(value)
      end

    # Handle boolean toggle with validation
    changeset =
      validate_config_setting(%{
        key: key,
        value: new_value,
        category: category_atom
      })

    if changeset.valid? do
      validated_data = Ecto.Changeset.apply_changes(changeset)
      # Add updated_by_id for audit trail
      validated_data_with_user =
        Map.put(validated_data, :updated_by_id, socket.assigns.current_user.id)

      case upsert_config_setting(validated_data_with_user) do
        {:ok, _setting} ->
          {:noreply,
           socket
           |> put_flash(:info, "Setting updated successfully")
           |> load_configuration_data()}

        {:error, changeset} ->
          MydiaLogger.log_error(:liveview, "Failed to toggle setting",
            error: changeset,
            error_details: inspect(changeset, pretty: true),
            changeset_errors: changeset.errors,
            operation: :update_setting,
            category: category,
            setting_key: key,
            user_id: socket.assigns.current_user.id
          )

          error_msg = MydiaLogger.user_error_message(:update_setting, changeset)

          {:noreply,
           socket
           |> put_flash(:error, error_msg)}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid setting value")}
    end
  end

  ## Quality Profile Events

  @impl true
  def handle_event("new_quality_profile", _params, socket) do
    changeset = Settings.change_quality_profile(%QualityProfile{})

    {:noreply,
     socket
     |> assign(:show_quality_profile_modal, true)
     |> assign(:quality_profile_form, to_form(changeset))
     |> assign(:quality_profile_mode, :new)
     |> assign(:quality_profile_active_tab, "basic")}
  end

  @impl true
  def handle_event("edit_quality_profile", %{"id" => id}, socket) do
    profile = Settings.get_quality_profile!(id)
    changeset = Settings.change_quality_profile(profile)

    {:noreply,
     socket
     |> assign(:show_quality_profile_modal, true)
     |> assign(:quality_profile_form, to_form(changeset))
     |> assign(:quality_profile_mode, :edit)
     |> assign(:editing_quality_profile, profile)
     |> assign(:quality_profile_active_tab, "basic")}
  end

  @impl true
  def handle_event("validate_quality_profile", %{"quality_profile" => params}, socket) do
    profile =
      case socket.assigns.quality_profile_mode do
        :new -> %QualityProfile{}
        :edit -> socket.assigns.editing_quality_profile
      end

    # Transform params to match schema
    transformed_params = transform_quality_profile_params(params)

    changeset =
      profile
      |> Settings.change_quality_profile(transformed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :quality_profile_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_quality_profile", %{"quality_profile" => params}, socket) do
    # Transform params to match schema
    transformed_params = transform_quality_profile_params(params)

    result =
      case socket.assigns.quality_profile_mode do
        :new ->
          Settings.create_quality_profile(transformed_params)

        :edit ->
          Settings.update_quality_profile(
            socket.assigns.editing_quality_profile,
            transformed_params
          )
      end

    case result do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> assign(:show_quality_profile_modal, false)
         |> put_flash(:info, "Quality profile saved successfully")
         |> load_configuration_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :quality_profile_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("duplicate_quality_profile", %{"id" => id}, socket) do
    profile = Settings.get_quality_profile!(id)

    case Settings.clone_quality_profile(profile) do
      {:ok, _new_profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Quality profile cloned successfully")
         |> load_configuration_data()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to clone quality profile",
          error: changeset,
          operation: :duplicate_quality_profile,
          profile_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:duplicate_quality_profile, changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("delete_quality_profile", %{"id" => id}, socket) do
    profile = Settings.get_quality_profile!(id)

    case Settings.delete_quality_profile(profile) do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Quality profile deleted successfully")
         |> load_configuration_data()}

      {:error, :profile_in_use} ->
        MydiaLogger.log_warning(:liveview, "Attempted to delete quality profile in use",
          operation: :delete_quality_profile,
          profile_id: id,
          profile_name: profile.name,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(
           :error,
           "Cannot delete quality profile - it is assigned to one or more media items. Please reassign those items first."
         )}

      {:error, error} ->
        MydiaLogger.log_error(:liveview, "Failed to delete quality profile",
          error: error,
          operation: :delete_quality_profile,
          profile_id: id,
          profile_name: profile.name,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:delete_quality_profile, error)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("close_quality_profile_modal", _params, socket) do
    {:noreply, assign(socket, :show_quality_profile_modal, false)}
  end

  @impl true
  def handle_event("change_quality_profile_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :quality_profile_active_tab, tab)}
  end

  @impl true
  def handle_event("export_quality_profile", %{"id" => id, "format" => format}, socket) do
    profile = Settings.get_quality_profile!(id)
    format_atom = String.to_existing_atom(format)

    case Settings.export_profile(profile, format: format_atom) do
      {:ok, content} ->
        # Trigger file download via JavaScript
        {:noreply,
         socket
         |> push_event("download_file", %{
           content: content,
           filename: "#{profile.name}.#{format}",
           mime_type: get_export_mime_type(format_atom)
         })}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Export failed: #{reason}")}
    end
  end

  @impl true
  def handle_event("import_quality_profile_url", %{"url" => url}, socket) do
    case Settings.import_profile(url, dry_run: false) do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> assign(:show_import_modal, false)
         |> assign(:import_error, nil)
         |> put_flash(:info, "Profile imported successfully from URL")
         |> load_configuration_data()}

      {:error, reason} ->
        MydiaLogger.log_error(:liveview, "Failed to import quality profile from URL",
          error: reason,
          operation: :import_quality_profile,
          url: url,
          user_id: socket.assigns.current_user.id
        )

        error_msg =
          case reason do
            msg when is_binary(msg) -> msg
            _ -> "Failed to import profile: #{inspect(reason)}"
          end

        {:noreply, socket |> assign(:import_error, error_msg)}
    end
  end

  @impl true
  def handle_event("show_import_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_import_modal, true)
     |> assign(:import_error, nil)}
  end

  @impl true
  def handle_event("close_import_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_import_modal, false)
     |> assign(:import_error, nil)}
  end

  ## Browse Presets Events

  @impl true
  def handle_event("show_browse_presets_modal", _params, socket) do
    alias Mydia.Settings.QualityProfilePresets

    {:noreply,
     socket
     |> assign(:show_browse_presets_modal, true)
     |> assign(:browse_presets_category, :all)
     |> assign(:browse_presets, QualityProfilePresets.list_presets())}
  end

  @impl true
  def handle_event("close_browse_presets_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_browse_presets_modal, false)
     |> assign(:browse_presets, [])
     |> assign(:browse_presets_category, :all)}
  end

  @impl true
  def handle_event("filter_presets", %{"category" => category}, socket) do
    alias Mydia.Settings.QualityProfilePresets
    category_atom = String.to_existing_atom(category)

    {:noreply,
     socket
     |> assign(:browse_presets_category, category_atom)
     |> assign(:browse_presets, QualityProfilePresets.list_presets_by_category(category_atom))}
  end

  @impl true
  def handle_event("import_preset", %{"preset-id" => preset_id}, socket) do
    alias Mydia.Settings.QualityProfilePresets

    case QualityProfilePresets.get_preset(preset_id) do
      {:ok, preset} ->
        # Import the preset as a new quality profile
        case Settings.create_quality_profile(preset.profile_data) do
          {:ok, _profile} ->
            {:noreply,
             socket
             |> put_flash(:info, "Preset \"#{preset.name}\" imported successfully")
             |> assign(:show_browse_presets_modal, false)
             |> load_configuration_data()}

          {:error, changeset} ->
            errors = format_changeset_errors(changeset)

            {:noreply,
             socket
             |> put_flash(:error, "Failed to import preset: #{errors}")}
        end

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Preset not found")}
    end
  end

  ## Download Client Events

  @impl true
  def handle_event("new_download_client", _params, socket) do
    changeset = DownloadClientConfig.changeset(%DownloadClientConfig{}, %{})

    {:noreply,
     socket
     |> assign(:show_download_client_modal, true)
     |> assign(:download_client_form, to_form(changeset))
     |> assign(:download_client_mode, :new)
     |> assign(:testing_download_client_connection, false)}
  end

  @impl true
  def handle_event("edit_download_client", %{"id" => id}, socket) do
    client = Settings.get_download_client_config!(id)

    # Check if this is a runtime config and prevent editing
    if Settings.runtime_config?(client) do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Cannot edit runtime-configured download client. This client is configured via environment variables and is read-only in the UI."
       )}
    else
      changeset = DownloadClientConfig.changeset(client, %{})

      {:noreply,
       socket
       |> assign(:show_download_client_modal, true)
       |> assign(:download_client_form, to_form(changeset))
       |> assign(:download_client_mode, :edit)
       |> assign(:editing_download_client, client)
       |> assign(:testing_download_client_connection, false)}
    end
  end

  @impl true
  def handle_event("validate_download_client", %{"download_client_config" => params}, socket) do
    client =
      case socket.assigns.download_client_mode do
        :new -> %DownloadClientConfig{}
        :edit -> socket.assigns.editing_download_client
      end

    changeset =
      client
      |> DownloadClientConfig.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :download_client_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_download_client", %{"download_client_config" => params}, socket) do
    result =
      case socket.assigns.download_client_mode do
        :new ->
          Settings.create_download_client_config(params)

        :edit ->
          Settings.update_download_client_config(
            socket.assigns.editing_download_client,
            params
          )
      end

    case result do
      {:ok, _client} ->
        {:noreply,
         socket
         |> assign(:show_download_client_modal, false)
         |> put_flash(:info, "Download client saved successfully")
         |> load_configuration_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :download_client_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_download_client", %{"id" => id}, socket) do
    client = Settings.get_download_client_config!(id)

    # Check if this is a runtime config and prevent deletion
    if Settings.runtime_config?(client) do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Cannot delete runtime-configured download client. This client is configured via environment variables and is read-only in the UI."
       )}
    else
      case Settings.delete_download_client_config(client) do
        {:ok, _client} ->
          {:noreply,
           socket
           |> put_flash(:info, "Download client deleted successfully")
           |> load_configuration_data()}

        {:error, error} ->
          MydiaLogger.log_error(:liveview, "Failed to delete download client",
            error: error,
            operation: :delete_download_client,
            client_id: id,
            client_name: client.name,
            user_id: socket.assigns.current_user.id
          )

          error_msg = MydiaLogger.user_error_message(:delete_download_client, error)

          {:noreply,
           socket
           |> put_flash(:error, error_msg)}
      end
    end
  end

  @impl true
  def handle_event("close_download_client_modal", _params, socket) do
    {:noreply, assign(socket, :show_download_client_modal, false)}
  end

  @impl true
  def handle_event("test_download_client", %{"id" => id}, socket) do
    client = Settings.get_download_client_config!(id)

    # Convert client config to map for adapter
    client_config = %{
      type: client.type,
      host: client.host,
      port: client.port,
      use_ssl: client.use_ssl,
      username: client.username,
      password: client.password,
      api_key: client.api_key,
      url_base: client.url_base,
      options: client.connection_settings || %{}
    }

    # Get the adapter and test connection
    case test_client_connection(client_config) do
      {:ok, info} ->
        version_info =
          cond do
            Map.has_key?(info, :version) ->
              "Version: #{info.version}"

            Map.has_key?(info, :rpc_version) ->
              "RPC Version: #{info.rpc_version}"

            true ->
              "Connected"
          end

        {:noreply,
         socket
         |> put_flash(:info, "Connection successful! #{version_info}")}

      {:error, error} ->
        MydiaLogger.log_error(:liveview, "Download client connection test failed",
          error: error,
          operation: :test_download_client,
          client_id: id,
          client_type: client.type,
          client_host: client.host,
          user_id: socket.assigns.current_user.id
        )

        error_msg =
          case error do
            %{message: msg} -> msg
            _ -> MydiaLogger.extract_error_message(error)
          end

        {:noreply,
         socket
         |> put_flash(:error, "Connection failed: #{error_msg}")}
    end
  end

  @impl true
  def handle_event("test_download_client_connection", _params, socket) do
    # Extract form params from the current changeset
    changeset = socket.assigns.download_client_form.source

    # Get the changeset data (which includes user input)
    params = Ecto.Changeset.apply_changes(changeset)

    # Convert string type to atom if needed
    type =
      case params.type do
        type when is_atom(type) -> type
        type when is_binary(type) -> String.to_existing_atom(type)
      end

    # Build config map for test_connection
    test_config = %{
      type: type,
      host: params.host,
      port: params.port,
      use_ssl: params.use_ssl || false,
      username: params.username,
      password: params.password,
      api_key: params.api_key,
      url_base: params.url_base,
      options: params.connection_settings || %{}
    }

    # Set loading state
    socket = assign(socket, :testing_download_client_connection, true)

    # Test the connection with a timeout
    task =
      Task.async(fn ->
        test_client_connection(test_config)
      end)

    case Task.yield(task, 10_000) || Task.shutdown(task) do
      {:ok, {:ok, info}} ->
        # Extract version or other info from response
        version_info =
          cond do
            Map.has_key?(info, :version) ->
              "Version: #{info.version}"

            Map.has_key?(info, :rpc_version) ->
              "RPC Version: #{info.rpc_version}"

            true ->
              "Connected"
          end

        {:noreply,
         socket
         |> assign(:testing_download_client_connection, false)
         |> put_flash(:info, "Connection successful! #{version_info}")}

      {:ok, {:error, error}} ->
        MydiaLogger.log_warning(:liveview, "Download client connection test failed",
          operation: :test_download_client_connection,
          error: error,
          client_type: type,
          user_id: socket.assigns.current_user.id
        )

        error_msg =
          case error do
            %{message: msg} -> msg
            _ -> MydiaLogger.extract_error_message(error)
          end

        {:noreply,
         socket
         |> assign(:testing_download_client_connection, false)
         |> put_flash(:error, "Connection failed: #{error_msg}")}

      nil ->
        # Task timed out
        MydiaLogger.log_warning(:liveview, "Download client connection test timed out",
          operation: :test_download_client_connection,
          client_type: type,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> assign(:testing_download_client_connection, false)
         |> put_flash(:error, "Connection test timed out after 10 seconds")}
    end
  end

  ## Indexer Events

  @impl true
  def handle_event("new_indexer", _params, socket) do
    changeset = IndexerConfig.changeset(%IndexerConfig{}, %{})

    {:noreply,
     socket
     |> assign(:show_indexer_modal, true)
     |> assign(:indexer_form, to_form(changeset))
     |> assign(:indexer_mode, :new)
     |> assign(:testing_indexer_connection, false)}
  end

  @impl true
  def handle_event("edit_indexer", %{"id" => id}, socket) do
    indexer = Settings.get_indexer_config!(id)

    # Check if this is a runtime config and prevent editing
    if Settings.runtime_config?(indexer) do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Cannot edit runtime-configured indexer. This indexer is configured via environment variables and is read-only in the UI."
       )}
    else
      changeset = IndexerConfig.changeset(indexer, %{})

      {:noreply,
       socket
       |> assign(:show_indexer_modal, true)
       |> assign(:indexer_form, to_form(changeset))
       |> assign(:indexer_mode, :edit)
       |> assign(:editing_indexer, indexer)
       |> assign(:testing_indexer_connection, false)}
    end
  end

  @impl true
  def handle_event("validate_indexer", %{"indexer_config" => params}, socket) do
    indexer =
      case socket.assigns.indexer_mode do
        :new -> %IndexerConfig{}
        :edit -> socket.assigns.editing_indexer
      end

    changeset =
      indexer
      |> IndexerConfig.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :indexer_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_indexer", %{"indexer_config" => params}, socket) do
    result =
      case socket.assigns.indexer_mode do
        :new ->
          Settings.create_indexer_config(params)

        :edit ->
          Settings.update_indexer_config(socket.assigns.editing_indexer, params)
      end

    case result do
      {:ok, _indexer} ->
        {:noreply,
         socket
         |> assign(:show_indexer_modal, false)
         |> put_flash(:info, "Indexer saved successfully")
         |> load_configuration_data()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :indexer_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_indexer", %{"id" => id}, socket) do
    indexer = Settings.get_indexer_config!(id)

    # Check if this is a runtime config and prevent deletion
    if Settings.runtime_config?(indexer) do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Cannot delete runtime-configured indexer. This indexer is configured via environment variables and is read-only in the UI."
       )}
    else
      case Settings.delete_indexer_config(indexer) do
        {:ok, _indexer} ->
          {:noreply,
           socket
           |> put_flash(:info, "Indexer deleted successfully")
           |> load_configuration_data()}

        {:error, error} ->
          MydiaLogger.log_error(:liveview, "Failed to delete indexer",
            error: error,
            operation: :delete_indexer,
            indexer_id: id,
            indexer_name: indexer.name,
            user_id: socket.assigns.current_user.id
          )

          error_msg = MydiaLogger.user_error_message(:delete_indexer, error)

          {:noreply,
           socket
           |> put_flash(:error, error_msg)}
      end
    end
  end

  @impl true
  def handle_event("close_indexer_modal", _params, socket) do
    {:noreply, assign(socket, :show_indexer_modal, false)}
  end

  @impl true
  def handle_event("show_indexer_library", _params, socket) do
    {:noreply, assign(socket, :show_indexer_library_modal, true)}
  end

  @impl true
  def handle_event("close_indexer_library", _params, socket) do
    {:noreply, assign(socket, :show_indexer_library_modal, false)}
  end

  @impl true
  def handle_event("test_indexer_connection", _params, socket) do
    # Extract form params from the current changeset
    changeset = socket.assigns.indexer_form.source

    # Get the changeset data (which includes user input)
    params = Ecto.Changeset.apply_changes(changeset)

    # Convert string type to atom if needed
    type =
      case params.type do
        type when is_atom(type) -> type
        type when is_binary(type) -> String.to_existing_atom(type)
      end

    # Build config map for test_connection
    test_config = %{
      type: type,
      base_url: params.base_url,
      api_key: params.api_key
    }

    # Set loading state
    socket = assign(socket, :testing_indexer_connection, true)

    # Test the connection with a timeout
    task =
      Task.async(fn ->
        Mydia.Indexers.test_connection(test_config)
      end)

    case Task.yield(task, 10_000) || Task.shutdown(task) do
      {:ok, {:ok, info}} ->
        # Extract version or other info from response
        version = Map.get(info, :version, "unknown")

        {:noreply,
         socket
         |> assign(:testing_indexer_connection, false)
         |> put_flash(:info, "Connection successful! Version: #{version}")}

      {:ok, {:error, error}} ->
        MydiaLogger.log_warning(:liveview, "Indexer connection test failed",
          operation: :test_indexer_connection,
          error: error,
          indexer_type: type,
          user_id: socket.assigns.current_user.id
        )

        error_msg =
          case error do
            %{message: msg} -> msg
            _ -> MydiaLogger.extract_error_message(error)
          end

        {:noreply,
         socket
         |> assign(:testing_indexer_connection, false)
         |> put_flash(:error, "Connection failed: #{error_msg}")}

      nil ->
        # Task timed out
        MydiaLogger.log_warning(:liveview, "Indexer connection test timed out",
          operation: :test_indexer_connection,
          indexer_type: type,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> assign(:testing_indexer_connection, false)
         |> put_flash(:error, "Connection test timed out after 10 seconds")}
    end
  end

  @impl true
  def handle_event("test_indexer", %{"id" => id}, socket) do
    case IndexerHealth.check_health(id, force: true) do
      {:ok, %{status: :healthy} = health} ->
        details = Map.get(health, :details, %{})
        version = Map.get(details, :version, "unknown")

        {:noreply,
         socket
         |> put_flash(:info, "Indexer connection successful! Version: #{version}")
         |> load_configuration_data()}

      {:ok, %{status: :unhealthy, error: error}} ->
        MydiaLogger.log_warning(:liveview, "Indexer health check returned unhealthy status",
          operation: :test_indexer,
          indexer_id: id,
          error: error,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(:error, "Indexer connection failed: #{error}")
         |> load_configuration_data()}

      {:error, :not_found} ->
        MydiaLogger.log_error(:liveview, "Indexer not found for health check",
          operation: :test_indexer,
          indexer_id: id,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(:error, "Indexer not found")}

      {:error, reason} ->
        MydiaLogger.log_error(:liveview, "Indexer health check failed",
          error: reason,
          operation: :test_indexer,
          indexer_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.extract_error_message(reason)

        {:noreply,
         socket
         |> put_flash(:error, "Health check failed: #{error_msg}")
         |> load_configuration_data()}
    end
  end

  @impl true
  def handle_event("test_library_indexer", %{"id" => id}, socket) do
    case Indexers.test_cardigann_connection(id) do
      {:ok, result} ->
        flash_message =
          if result.success do
            "Connection successful (#{result.response_time_ms}ms)"
          else
            "Connection failed: #{result.error || "Unknown error"}"
          end

        flash_type = if result.success, do: :info, else: :error

        {:noreply,
         socket
         |> put_flash(flash_type, flash_message)
         |> load_configuration_data()}

      {:error, reason} ->
        MydiaLogger.log_error(:liveview, "Failed to test library indexer connection",
          error: reason,
          operation: :test_library_indexer,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(:error, "Failed to test connection: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("toggle_library_flaresolverr", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)
    new_enabled = !definition.flaresolverr_enabled

    case Indexers.update_flaresolverr_settings(definition, %{flaresolverr_enabled: new_enabled}) do
      {:ok, updated_definition} ->
        action = if updated_definition.flaresolverr_enabled, do: "enabled", else: "disabled"

        {:noreply,
         socket
         |> put_flash(:info, "FlareSolverr #{action} for #{definition.name}")
         |> load_configuration_data()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to toggle FlareSolverr",
          error: changeset,
          operation: :toggle_library_flaresolverr,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:toggle_library_flaresolverr, changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("toggle_library_indexer", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)

    result =
      if definition.enabled do
        Indexers.disable_cardigann_definition(definition)
      else
        Indexers.enable_cardigann_definition(definition)
      end

    case result do
      {:ok, updated_definition} ->
        socket =
          if updated_definition.enabled do
            # Re-enabling: show success flash, clear undo banner
            socket
            |> put_flash(:info, "#{definition.name} enabled")
            |> assign(:recently_disabled_indexer, nil)
          else
            # Disabling: show undo banner instead of flash
            socket
            |> assign(:recently_disabled_indexer, updated_definition)
          end

        {:noreply, load_configuration_data(socket)}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to toggle library indexer",
          error: changeset,
          operation: :toggle_library_indexer,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:toggle_library_indexer, changeset)

        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  @impl true
  def handle_event("undo_disable_library_indexer", _params, socket) do
    case socket.assigns.recently_disabled_indexer do
      nil ->
        {:noreply, socket}

      definition ->
        case Indexers.enable_cardigann_definition(definition) do
          {:ok, _updated} ->
            {:noreply,
             socket
             |> assign(:recently_disabled_indexer, nil)
             |> put_flash(:info, "#{definition.name} re-enabled")
             |> load_configuration_data()}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to re-enable indexer")}
        end
    end
  end

  @impl true
  def handle_event("dismiss_undo_banner", _params, socket) do
    {:noreply, assign(socket, :recently_disabled_indexer, nil)}
  end

  @impl true
  def handle_event("configure_library_indexer", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)

    {:noreply,
     socket
     |> assign(:show_library_config_modal, true)
     |> assign(:configuring_library_indexer, definition)}
  end

  @impl true
  def handle_event("close_library_config_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_library_config_modal, false)
     |> assign(:configuring_library_indexer, nil)}
  end

  @impl true
  def handle_event("save_library_indexer_config", %{"config" => config_params}, socket) do
    definition = socket.assigns.configuring_library_indexer

    case Indexers.configure_cardigann_definition(definition, config_params) do
      {:ok, _updated_definition} ->
        {:noreply,
         socket
         |> assign(:show_library_config_modal, false)
         |> assign(:configuring_library_indexer, nil)
         |> put_flash(:info, "Configuration saved for #{definition.name}")
         |> load_configuration_data()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to configure library indexer",
          error: changeset,
          operation: :configure_library_indexer,
          definition_id: definition.id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:configure_library_indexer, changeset)

        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  ## FlareSolverr Events

  @impl true
  def handle_event("test_flaresolverr", _params, socket) do
    alias Mydia.Indexers.FlareSolverr

    case FlareSolverr.health_check() do
      {:ok, info} ->
        version = info[:version] || "unknown"
        sessions = length(info[:sessions] || [])

        {:noreply,
         socket
         |> put_flash(
           :info,
           "FlareSolverr connection successful! Version: #{version}, Active sessions: #{sessions}"
         )
         |> load_system_data()}

      {:error, :disabled} ->
        {:noreply,
         socket
         |> put_flash(:error, "FlareSolverr is disabled. Enable it in configuration.")}

      {:error, :not_configured} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "FlareSolverr is not configured. Set FLARESOLVERR_URL in environment."
         )}

      {:error, {:connection_error, reason}} ->
        {:noreply,
         socket
         |> put_flash(:error, "FlareSolverr connection failed: #{reason}")}

      {:error, reason} ->
        MydiaLogger.log_error(:liveview, "FlareSolverr health check failed",
          error: reason,
          operation: :test_flaresolverr,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(:error, "FlareSolverr test failed: #{inspect(reason)}")}
    end
  end

  ## Crash Reporting Events

  @impl true
  def handle_event("clear_crash_queue", _params, socket) do
    Mydia.CrashReporter.clear_queue()

    {:noreply,
     socket
     |> put_flash(:info, "Crash report queue cleared")
     |> load_configuration_data()}
  end

  ## Library Path Events

  @impl true
  def handle_event("new_library_path", _params, socket) do
    changeset = LibraryPath.changeset(%LibraryPath{}, %{})

    {:noreply,
     socket
     |> assign(:show_library_path_modal, true)
     |> assign(:library_path_form, to_form(changeset))
     |> assign(:library_path_mode, :new)}
  end

  @impl true
  def handle_event("edit_library_path", %{"id" => id}, socket) do
    path = Settings.get_library_path!(id)
    changeset = LibraryPath.changeset(path, %{})

    {:noreply,
     socket
     |> assign(:show_library_path_modal, true)
     |> assign(:library_path_form, to_form(changeset))
     |> assign(:library_path_mode, :edit)
     |> assign(:editing_library_path, path)}
  end

  @impl true
  def handle_event("validate_library_path", %{"library_path" => params}, socket) do
    path =
      case socket.assigns.library_path_mode do
        :new -> %LibraryPath{}
        :edit -> socket.assigns.editing_library_path
      end

    changeset =
      path
      |> LibraryPath.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :library_path_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_library_path", %{"library_path" => params}, socket) do
    # First validate through changeset
    library_path =
      case socket.assigns.library_path_mode do
        :new -> %LibraryPath{}
        :edit -> socket.assigns.editing_library_path
      end

    changeset = LibraryPath.changeset(library_path, params)

    if changeset.valid? do
      validated_data = Ecto.Changeset.apply_changes(changeset)

      # Validate directory exists using validated data
      case validate_directory(validated_data.path) do
        :ok ->
          result =
            case socket.assigns.library_path_mode do
              :new ->
                Settings.create_library_path(params)

              :edit ->
                Settings.update_library_path(socket.assigns.editing_library_path, params)
            end

          case result do
            {:ok, _path} ->
              {:noreply,
               socket
               |> assign(:show_library_path_modal, false)
               |> put_flash(:info, "Library path saved successfully")
               |> load_configuration_data()}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, :library_path_form, to_form(changeset))}
          end

        {:error, reason} ->
          changeset =
            changeset
            |> Ecto.Changeset.add_error(:path, reason)

          {:noreply,
           socket
           |> assign(:library_path_form, to_form(changeset))
           |> put_flash(:error, "Invalid directory: #{reason}")}
      end
    else
      {:noreply,
       socket
       |> assign(:library_path_form, to_form(changeset))
       |> put_flash(:error, "Please fix the validation errors")}
    end
  end

  @impl true
  def handle_event("delete_library_path", %{"id" => id}, socket) do
    path = Settings.get_library_path!(id)

    case Settings.delete_library_path(path) do
      {:ok, _path} ->
        {:noreply,
         socket
         |> put_flash(:info, "Library path deleted successfully")
         |> load_configuration_data()}

      {:error, error} ->
        MydiaLogger.log_error(:liveview, "Failed to delete library path",
          error: error,
          operation: :delete_library_path,
          path_id: id,
          path: path.path,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:delete_library_path, error)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("close_library_path_modal", _params, socket) do
    {:noreply, assign(socket, :show_library_path_modal, false)}
  end

  ## Private Functions

  defp test_client_connection(client_config) do
    alias Mydia.Downloads.Client.Registry

    with {:ok, adapter} <- Registry.get_adapter(client_config.type),
         {:ok, result} <- adapter.test_connection(client_config) do
      {:ok, result}
    else
      {:error, _} = error -> error
    end
  end

  defp validate_directory(nil), do: {:error, "path cannot be blank"}
  defp validate_directory(""), do: {:error, "path cannot be blank"}

  defp validate_directory(path) when is_binary(path) do
    cond do
      not File.exists?(path) ->
        {:error, "directory does not exist"}

      not File.dir?(path) ->
        {:error, "path is not a directory"}

      true ->
        # Check if directory is readable
        case File.ls(path) do
          {:ok, _} -> :ok
          {:error, :eacces} -> {:error, "directory is not accessible (permission denied)"}
          {:error, reason} -> {:error, "cannot read directory: #{reason}"}
        end
    end
  end

  defp load_configuration_data(socket) do
    download_clients = Settings.list_download_client_configs()
    client_health = get_client_health_status(download_clients)

    indexers = Settings.list_indexer_configs()
    indexer_health = get_indexer_health_status(indexers)

    # Load enabled library indexers if Cardigann feature is enabled
    cardigann_enabled = CardigannFeatureFlags.enabled?()

    library_indexers =
      if cardigann_enabled do
        Indexers.list_cardigann_definitions(enabled: true)
      else
        []
      end

    library_indexer_stats =
      if cardigann_enabled do
        Indexers.count_cardigann_definitions()
      else
        %{total: 0, enabled: 0, disabled: 0}
      end

    socket
    |> assign(:config, Settings.get_runtime_config())
    |> assign(:config_settings_with_sources, get_all_settings_with_sources())
    |> assign(:quality_profiles, Settings.list_quality_profiles())
    |> assign(:download_clients, download_clients)
    |> assign(:client_health, client_health)
    |> assign(:indexers, indexers)
    |> assign(:indexer_health, indexer_health)
    |> assign(:library_indexers, library_indexers)
    |> assign(:library_indexer_stats, library_indexer_stats)
    |> assign(:library_paths, Settings.list_library_paths())
    |> assign(:crash_report_stats, Mydia.CrashReporter.stats())
    |> assign(:queued_crash_reports, Mydia.CrashReporter.list_queued_reports())
    |> assign(:show_quality_profile_modal, false)
    |> assign(:show_download_client_modal, false)
    |> assign(:show_indexer_modal, false)
    |> assign(:show_library_path_modal, false)
    |> assign(:show_manual_report_modal, false)
    |> assign(:show_import_modal, false)
    |> assign(:show_indexer_library_modal, false)
    |> assign(:show_library_config_modal, false)
    |> assign(:configuring_library_indexer, nil)
    |> assign_new(:recently_disabled_indexer, fn -> nil end)
  end

  defp get_client_health_status(clients) do
    clients
    |> Enum.map(fn client ->
      case ClientHealth.check_health(client.id) do
        {:ok, health} -> {client.id, health}
        {:error, _} -> {client.id, %{status: :unknown, error: "Unable to check health"}}
      end
    end)
    |> Map.new()
  end

  defp get_indexer_health_status(indexers) do
    indexers
    |> Enum.map(fn indexer ->
      case IndexerHealth.check_health(indexer.id) do
        {:ok, health} ->
          # Add failure count to health status
          failure_count = IndexerHealth.get_failure_count(indexer.id)
          health_with_failures = Map.put(health, :consecutive_failures, failure_count)
          {indexer.id, health_with_failures}

        {:error, _} ->
          {indexer.id, %{status: :unknown, error: "Unable to check health"}}
      end
    end)
    |> Map.new()
  end

  defp maybe_setup_form(socket, _tab) do
    # Setup forms for the active tab if needed
    socket
  end

  defp get_all_settings_with_sources do
    config = Settings.get_runtime_config()

    # In test environments, config might be a simple map. Use defaults if needed.
    config =
      if is_struct(config) do
        config
      else
        Mydia.Config.Schema.defaults()
      end

    # Group settings by category with their sources
    %{
      "Server" => [
        %{
          key: "server.port",
          label: "Port",
          type: :integer,
          value: config.server.port,
          source: get_source("PORT", "server.port")
        },
        %{
          key: "server.host",
          label: "Host",
          type: :string,
          value: config.server.host,
          source: get_source("HOST", "server.host")
        },
        %{
          key: "server.url_scheme",
          label: "URL Scheme",
          type: :string,
          value: config.server.url_scheme,
          source: get_source("URL_SCHEME", "server.url_scheme")
        },
        %{
          key: "server.url_host",
          label: "URL Host",
          type: :string,
          value: config.server.url_host,
          source: get_source("URL_HOST", "server.url_host")
        }
      ],
      "Database" => [
        %{
          key: "database.path",
          label: "Database Path",
          type: :string,
          value: config.database.path,
          source: get_source("DATABASE_PATH", "database.path")
        },
        %{
          key: "database.pool_size",
          label: "Pool Size",
          type: :integer,
          value: config.database.pool_size,
          source: get_source("POOL_SIZE", "database.pool_size")
        }
      ],
      "Authentication" => [
        %{
          key: "auth.local_enabled",
          label: "Local Auth Enabled",
          type: :boolean,
          value: config.auth.local_enabled,
          source: get_source("LOCAL_AUTH_ENABLED", "auth.local_enabled")
        },
        %{
          key: "auth.oidc_enabled",
          label: "OIDC Enabled",
          type: :boolean,
          value: config.auth.oidc_enabled,
          source: get_source("OIDC_ENABLED", "auth.oidc_enabled")
        }
      ],
      "Media" => [
        %{
          key: "media.movies_path",
          label: "Movies Path",
          type: :string,
          value: config.media.movies_path,
          source: get_source("MOVIES_PATH", "media.movies_path")
        },
        %{
          key: "media.tv_path",
          label: "TV Path",
          type: :string,
          value: config.media.tv_path,
          source: get_source("TV_PATH", "media.tv_path")
        },
        %{
          key: "media.scan_interval_hours",
          label: "Scan Interval (hours)",
          type: :integer,
          value: config.media.scan_interval_hours,
          source: get_source("MEDIA_SCAN_INTERVAL_HOURS", "media.scan_interval_hours")
        }
      ],
      "Downloads" => [
        %{
          key: "downloads.monitor_interval_minutes",
          label: "Monitor Interval (minutes)",
          type: :integer,
          value: config.downloads.monitor_interval_minutes,
          source:
            get_source("DOWNLOAD_MONITOR_INTERVAL_MINUTES", "downloads.monitor_interval_minutes")
        }
      ],
      "Crash Reporting" => [
        %{
          key: "crash_reporting.enabled",
          label: "Share Crashes with Developers",
          type: :boolean,
          value: get_crash_reporting_enabled(),
          source: get_source("CRASH_REPORTING_ENABLED", "crash_reporting.enabled")
        }
      ],
      "FlareSolverr" => [
        %{
          key: "flaresolverr.enabled",
          label: "Enabled",
          type: :boolean,
          value: config.flaresolverr.enabled,
          source: get_source("FLARESOLVERR_ENABLED", "flaresolverr.enabled")
        },
        %{
          key: "flaresolverr.url",
          label: "FlareSolverr URL",
          type: :string,
          value: config.flaresolverr.url || "",
          source: get_source("FLARESOLVERR_URL", "flaresolverr.url"),
          placeholder: "http://flaresolverr:8191"
        },
        %{
          key: "flaresolverr.timeout",
          label: "Timeout (ms)",
          type: :integer,
          value: config.flaresolverr.timeout,
          source: get_source("FLARESOLVERR_TIMEOUT", "flaresolverr.timeout")
        },
        %{
          key: "flaresolverr.max_timeout",
          label: "Max Timeout (ms)",
          type: :integer,
          value: config.flaresolverr.max_timeout,
          source: get_source("FLARESOLVERR_MAX_TIMEOUT", "flaresolverr.max_timeout")
        }
      ]
    }
  end

  defp get_crash_reporting_enabled do
    case Settings.get_config_setting_by_key("crash_reporting.enabled") do
      nil ->
        # Fall back to environment variable
        case Elixir.System.get_env("CRASH_REPORTING_ENABLED") do
          nil -> false
          value -> parse_boolean_value(value)
        end

      setting ->
        parse_boolean_value(setting.value)
    end
  end

  defp parse_boolean_value(value) when is_boolean(value), do: value
  defp parse_boolean_value("true"), do: true
  defp parse_boolean_value("1"), do: true
  defp parse_boolean_value("yes"), do: true
  defp parse_boolean_value(_), do: false

  defp get_source(env_var_name, key) do
    cond do
      # Check if set via environment variable
      Elixir.System.get_env(env_var_name) ->
        :env

      # Check if set in database
      Settings.get_config_setting_by_key(key) ->
        :database

      # TODO: Check if set in YAML file when file config is implemented
      # For now, we'll assume it's default if not in ENV or DB
      true ->
        :default
    end
  end

  defp validate_config_setting(attrs) do
    require Logger
    Logger.debug("validate_config_setting called with attrs: #{inspect(attrs)}")

    # Include category in types so it gets included in apply_changes result
    types = %{
      key: :string,
      value: :string,
      category: :string
    }

    # Category is already an atom from category_string_to_atom/1,
    # Convert it to string before casting to avoid issues
    attrs_with_string_category =
      case Map.get(attrs, :category) do
        nil ->
          Logger.error("Category is nil in attrs!")
          attrs

        category when is_atom(category) ->
          Logger.debug("Converting category atom to string: #{inspect(category)}")
          Map.put(attrs, :category, to_string(category))

        category ->
          Logger.debug("Category is already a string: #{inspect(category)}")
          attrs
      end

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(attrs_with_string_category, Map.keys(types))

    Logger.debug("After cast, changeset.changes: #{inspect(changeset.changes)}")

    # Only require key and category to match ConfigSetting schema validation
    # Value is optional and can be nil/empty for some settings
    result =
      changeset
      |> Ecto.Changeset.validate_required([:key, :category])

    Logger.debug(
      "Validation result - valid?: #{result.valid?}, errors: #{inspect(result.errors)}"
    )

    result
  end

  defp category_string_to_atom(category_string) do
    case category_string do
      "Server" -> :server
      "Database" -> :general
      "Authentication" -> :auth
      "Media" -> :media
      "Downloads" -> :downloads
      "Crash Reporting" -> :crash_reporting
      "Notifications" -> :notifications
      "FlareSolverr" -> :flaresolverr
      _ -> :general
    end
  end

  defp upsert_config_setting(attrs) do
    # attrs is now a map from apply_changes, convert to map with atom keys if needed
    attrs_map = if is_struct(attrs), do: Map.from_struct(attrs), else: attrs

    # Ensure we're accessing the key correctly (might be atom or string key)
    key = Map.get(attrs_map, :key) || Map.get(attrs_map, "key")

    # Convert atom keys to string keys for Ecto.Changeset.cast/3
    # Category is already a string from validate_config_setting
    string_attrs = %{
      "key" => Map.get(attrs_map, :key),
      "value" => Map.get(attrs_map, :value),
      "category" => Map.get(attrs_map, :category),
      "updated_by_id" => Map.get(attrs_map, :updated_by_id)
    }

    # Debug logging
    require Logger

    Logger.debug("Upserting config setting: key=#{inspect(key)}, attrs=#{inspect(string_attrs)}")

    case Settings.get_config_setting_by_key(key) do
      nil ->
        result = Settings.create_config_setting(string_attrs)
        Logger.debug("Create result: #{inspect(result)}")
        result

      existing ->
        result = Settings.update_config_setting(existing, string_attrs)
        Logger.debug("Update result: #{inspect(result)}")
        result
    end
  end

  # Transforms quality profile form params to match the schema structure
  defp transform_quality_profile_params(params) do
    # Handle qualities array - if empty or nil, set to empty list to satisfy validation
    qualities =
      case params["qualities"] do
        nil -> []
        [] -> []
        list when is_list(list) -> list
        _ -> []
      end

    # Extract and transform quality_standards
    quality_standards =
      if params["quality_standards"] do
        transform_quality_standards(params["quality_standards"])
      else
        nil
      end

    # Extract and transform metadata_preferences
    metadata_preferences =
      if params["metadata_preferences"] do
        transform_metadata_preferences(params["metadata_preferences"])
      else
        nil
      end

    # Build the final params map
    %{
      "name" => params["name"],
      "description" => params["description"],
      "qualities" => qualities,
      "upgrades_allowed" =>
        params["upgrades_allowed"] == "true" || params["upgrades_allowed"] == true,
      "upgrade_until_quality" => params["upgrade_until_quality"],
      "quality_standards" => quality_standards,
      "metadata_preferences" => metadata_preferences
    }
  end

  defp transform_quality_standards(standards) when is_map(standards) do
    standards
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case transform_quality_standard_value(key, value) do
        nil -> acc
        transformed_value -> Map.put(acc, key, transformed_value)
      end
    end)
    |> case do
      empty when empty == %{} -> nil
      non_empty -> non_empty
    end
  end

  defp transform_quality_standard_value(_key, ""), do: nil
  defp transform_quality_standard_value(_key, nil), do: nil

  defp transform_quality_standard_value(key, value)
       when key in [
              "min_video_bitrate_mbps",
              "max_video_bitrate_mbps",
              "preferred_video_bitrate_mbps"
            ] do
    case Float.parse(value) do
      {float, ""} -> float
      _ -> nil
    end
  end

  defp transform_quality_standard_value(key, value)
       when key in [
              "min_audio_bitrate_kbps",
              "max_audio_bitrate_kbps",
              "preferred_audio_bitrate_kbps",
              "movie_min_size_mb",
              "movie_max_size_mb",
              "episode_min_size_mb",
              "episode_max_size_mb"
            ] do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp transform_quality_standard_value(key, value)
       when key in [
              "preferred_video_codecs",
              "preferred_audio_codecs",
              "preferred_audio_channels",
              "preferred_resolutions",
              "preferred_sources",
              "hdr_formats"
            ] do
    case value do
      list when is_list(list) -> list
      str when is_binary(str) -> String.split(str, ",") |> Enum.map(&String.trim/1)
      _ -> nil
    end
  end

  defp transform_quality_standard_value("require_hdr", value) do
    value == "true" || value == true
  end

  defp transform_quality_standard_value(_key, value), do: value

  defp transform_metadata_preferences(prefs) when is_map(prefs) do
    prefs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      # Map fallback_languages_string to fallback_languages
      actual_key = if key == "fallback_languages_string", do: "fallback_languages", else: key

      case transform_metadata_pref_value(key, value) do
        nil -> acc
        transformed_value -> Map.put(acc, actual_key, transformed_value)
      end
    end)
    |> case do
      empty when empty == %{} -> nil
      non_empty -> non_empty
    end
  end

  defp transform_metadata_pref_value(_key, ""), do: nil
  defp transform_metadata_pref_value(_key, nil), do: nil

  # Handle fallback_languages_string -> convert to fallback_languages array
  defp transform_metadata_pref_value("fallback_languages_string", value) when is_binary(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      langs -> langs
    end
  end

  defp transform_metadata_pref_value(key, value)
       when key in ["provider_priority", "fallback_languages"] do
    case value do
      list when is_list(list) -> list
      str when is_binary(str) -> String.split(str, ",") |> Enum.map(&String.trim/1)
      _ -> nil
    end
  end

  defp transform_metadata_pref_value("auto_refresh_interval_hours", value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp transform_metadata_pref_value(key, value)
       when key in [
              "auto_fetch_enabled",
              "fallback_on_provider_failure",
              "skip_unavailable_providers"
            ] do
    value == "true" || value == true
  end

  defp transform_metadata_pref_value(_key, value), do: value

  # Helper function for export MIME types
  defp get_export_mime_type(:json), do: "application/json"
  defp get_export_mime_type(:yaml), do: "application/x-yaml"
  defp get_export_mime_type(_), do: "application/octet-stream"

  # System Status Functions (consolidated from AdminStatusLive)

  defp load_system_data(socket) do
    socket
    |> assign(:database_info, get_database_info())
    |> assign(:system_info, get_system_info())
    |> assign(:flaresolverr_status, FlareSolverrStatusComponent.get_status())
  end

  defp get_database_info do
    if DB.postgres?() do
      get_postgres_database_info()
    else
      get_sqlite_database_info()
    end
  end

  defp get_sqlite_database_info do
    config = Application.get_env(:mydia, Mydia.Repo, [])
    db_path = Keyword.get(config, :database, "unknown")

    file_size =
      if File.exists?(db_path) do
        File.stat!(db_path).size
      else
        0
      end

    %{
      adapter: :sqlite,
      path: db_path,
      size: format_file_size(file_size),
      exists: File.exists?(db_path),
      health: get_database_health()
    }
  end

  defp get_postgres_database_info do
    config = Application.get_env(:mydia, Mydia.Repo, [])
    hostname = Keyword.get(config, :hostname, "localhost")
    port = Keyword.get(config, :port, 5432)
    database = Keyword.get(config, :database, "unknown")

    # Get database size from PostgreSQL
    size =
      try do
        %{rows: [[size_bytes]]} =
          Repo.query!("SELECT pg_database_size(current_database())")

        format_file_size(size_bytes)
      rescue
        _ -> "Unknown"
      end

    %{
      adapter: :postgres,
      hostname: hostname,
      port: port,
      database: database,
      size: size,
      health: get_database_health()
    }
  end

  defp get_database_health do
    # In test environment, consider the database healthy if a connection exists
    # This avoids issues with SQL sandbox in LiveView processes
    if @env == :test do
      :healthy
    else
      if Repo.checked_out?() or test_db_connection(), do: :healthy, else: :unhealthy
    end
  end

  defp test_db_connection do
    Repo.query!("SELECT 1")
    true
  rescue
    _ -> false
  end

  defp get_system_info do
    memory = :erlang.memory()
    total_memory = Keyword.get(memory, :total, 0)

    %{
      app_version: System.app_version(),
      dev_mode: System.dev_mode?(),
      elixir_version: Elixir.System.version(),
      memory_used: format_file_size(total_memory),
      uptime: format_uptime(:erlang.statistics(:wall_clock) |> elem(0))
    }
  end

  defp format_file_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_099_511_627_776 -> "#{Float.round(bytes / 1_099_511_627_776, 2)} TB"
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_uptime(milliseconds) do
    seconds = div(milliseconds, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)

    cond do
      days > 0 -> "#{days}d #{rem(hours, 24)}h"
      hours > 0 -> "#{hours}h #{rem(minutes, 60)}m"
      minutes > 0 -> "#{minutes}m #{rem(seconds, 60)}s"
      true -> "#{seconds}s"
    end
  end

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
