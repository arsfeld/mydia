# Mydia Plugin System Design

## Overview

This document describes the plugin architecture for Mydia, building on the existing hooks infrastructure to provide a flexible, extensible system for integrating third-party services and custom functionality.

## Goals

1. **Extensibility**: Enable users to add functionality without modifying core code
2. **Type Safety**: Leverage Elixir behaviours for well-defined plugin contracts
3. **Reliability**: Fail-soft design where plugin failures don't break core functionality
4. **Discoverability**: Automatic plugin discovery and registration
5. **Configuration**: Simple YAML-based configuration
6. **Developer Experience**: Clear patterns and examples for plugin development

## Architecture

### Three-Tier Plugin System

```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                  │
│  (Media management, downloads, imports, etc.)       │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                    Hooks Layer                      │
│  • Event-driven execution points                    │
│  • Lua scripts for data transformation              │
│  • Priority-based execution order                   │
│  • Synchronous data modification                    │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                   Plugins Layer                     │
│  • Elixir behaviour-based modules                   │
│  • Type-safe contracts                              │
│  • Asynchronous notifications & integrations        │
│  • External service communication                   │
└─────────────────────────────────────────────────────┘
```

### Key Differences: Hooks vs Plugins

| Aspect | Hooks (Existing) | Plugins (New) |
|--------|------------------|---------------|
| **Language** | Lua scripts | Elixir modules |
| **Purpose** | Data transformation & validation | External integrations & services |
| **Execution** | Synchronous (blocking) | Async preferred (non-blocking) |
| **Discovery** | File-based (directory scanning) | Module-based (Application config) |
| **Return Value** | Modified data | Success/failure status |
| **Type Safety** | Runtime | Compile-time via behaviours |
| **Use Cases** | Modify metadata, validate releases | Send notifications, webhook calls |

## Plugin Types

### 1. Notification Plugins

**Purpose**: Send notifications to external services when events occur

**Behaviour**: `Mydia.Plugins.Notification`

```elixir
defmodule Mydia.Plugins.Notification do
  @moduledoc """
  Behaviour for notification plugins that send alerts to external services.
  """

  @type config :: map()
  @type event :: String.t()
  @type event_data :: map()
  @type notification_result :: {:ok, map()} | {:error, term()}

  @doc """
  Test connection to the notification service.
  Returns {:ok, info} if successful, {:error, reason} otherwise.
  """
  @callback test_connection(config) :: {:ok, map()} | {:error, term()}

  @doc """
  Send a notification for the given event.
  Should be async-friendly and fail gracefully.
  """
  @callback notify(event, event_data, config) :: notification_result()

  @doc """
  Return plugin metadata.
  """
  @callback plugin_info() :: %{
    name: String.t(),
    description: String.t(),
    version: String.t(),
    config_schema: map()
  }
end
```

**Example Implementation: Ntfy Plugin**

```elixir
defmodule Mydia.Plugins.Notifications.Ntfy do
  @behaviour Mydia.Plugins.Notification

  require Logger

  @impl true
  def plugin_info do
    %{
      name: "Ntfy",
      description: "Send notifications via ntfy.sh or self-hosted ntfy server",
      version: "1.0.0",
      config_schema: %{
        enabled: :boolean,
        server_url: :string,  # Default: "https://ntfy.sh"
        topic: :string,       # Required
        priority: :integer,   # 1-5, default 3
        tags: [:string],      # Optional tags
        auth_token: :string   # Optional for private topics
      }
    }
  end

  @impl true
  def test_connection(config) do
    url = build_url(config)

    case Req.post(url, json: %{message: "Mydia connection test", priority: 1}) do
      {:ok, %{status: 200}} ->
        {:ok, %{status: "connected", server: config.server_url}}
      {:error, reason} ->
        {:error, "Failed to connect to ntfy: #{inspect(reason)}"}
    end
  end

  @impl true
  def notify(event, event_data, config) do
    unless config.enabled do
      {:ok, %{skipped: true, reason: "plugin disabled"}}
    end

    message = format_message(event, event_data)
    payload = build_payload(message, event, config)
    url = build_url(config)

    case Req.post(url, json: payload, headers: auth_headers(config)) do
      {:ok, %{status: 200}} ->
        Logger.debug("[Ntfy] Notification sent: #{event}")
        {:ok, %{sent: true, event: event}}

      {:error, reason} ->
        Logger.warning("[Ntfy] Failed to send notification: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helpers

  defp build_url(config) do
    server = Map.get(config, :server_url, "https://ntfy.sh")
    topic = config.topic
    "#{server}/#{topic}"
  end

  defp build_payload(message, event, config) do
    %{
      message: message,
      title: event_title(event),
      priority: Map.get(config, :priority, 3),
      tags: Map.get(config, :tags, default_tags(event))
    }
  end

  defp format_message(event, data) do
    case event do
      "after_media_added" ->
        media = data.media_item
        "Added: #{media.title} (#{media.year})"

      "on_download_completed" ->
        "Download completed: #{data.release_name}"

      "after_import_completed" ->
        "Import completed: #{data.file_path}"

      _ ->
        "Mydia event: #{event}"
    end
  end

  defp event_title(event) do
    event
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp default_tags("after_media_added"), do: ["tv", "movie"]
  defp default_tags("on_download_completed"), do: ["inbox_down"]
  defp default_tags("after_import_completed"), do: ["white_check_mark"]
  defp default_tags(_), do: ["information_source"]

  defp auth_headers(%{auth_token: token}) when is_binary(token) do
    [{"Authorization", "Bearer #{token}"}]
  end
  defp auth_headers(_), do: []
end
```

### 2. Enrichment Plugins

**Purpose**: Fetch additional metadata or information from external sources

**Behaviour**: `Mydia.Plugins.Enrichment`

```elixir
defmodule Mydia.Plugins.Enrichment do
  @moduledoc """
  Behaviour for plugins that enrich media metadata from external sources.
  """

  @type config :: map()
  @type media_item :: map()
  @type enrichment_result :: {:ok, map()} | {:error, term()}

  @callback test_connection(config) :: {:ok, map()} | {:error, term()}

  @callback enrich(media_item, config) :: enrichment_result()

  @callback plugin_info() :: map()
end
```

**Example: AniList Plugin** (anime metadata)

```elixir
defmodule Mydia.Plugins.Enrichment.AniList do
  @behaviour Mydia.Plugins.Enrichment

  @impl true
  def plugin_info do
    %{
      name: "AniList",
      description: "Enrich anime metadata using AniList GraphQL API",
      version: "1.0.0",
      config_schema: %{
        enabled: :boolean,
        prefer_over_tmdb: :boolean  # Use AniList data over TMDB for anime
      }
    }
  end

  @impl true
  def enrich(media_item, config) do
    # Only enrich if it's an anime
    unless is_anime?(media_item), do: return {:ok, %{enriched: false}}

    with {:ok, anilist_data} <- search_anilist(media_item.title),
         enriched_data <- merge_metadata(media_item, anilist_data) do
      {:ok, %{enriched: true, data: enriched_data}}
    end
  end

  # Implementation details...
end
```

### 3. Webhook Plugins

**Purpose**: Send HTTP webhooks to external services

**Behaviour**: `Mydia.Plugins.Webhook`

```elixir
defmodule Mydia.Plugins.Webhook do
  @moduledoc """
  Behaviour for webhook plugins that send HTTP requests to external services.
  """

  @type config :: map()
  @type event :: String.t()
  @type event_data :: map()
  @type webhook_result :: {:ok, map()} | {:error, term()}

  @callback send_webhook(event, event_data, config) :: webhook_result()

  @callback plugin_info() :: map()
end
```

**Example: Discord Webhook Plugin**

```elixir
defmodule Mydia.Plugins.Webhooks.Discord do
  @behaviour Mydia.Plugins.Webhook

  @impl true
  def send_webhook(event, event_data, config) do
    embed = build_discord_embed(event, event_data)

    Req.post(config.webhook_url, json: %{embeds: [embed]})
  end

  defp build_discord_embed("after_media_added", data) do
    media = data.media_item
    %{
      title: "Media Added",
      description: media.title,
      color: 0x00ff00,
      fields: [
        %{name: "Year", value: to_string(media.year), inline: true},
        %{name: "Type", value: media.type, inline: true}
      ],
      thumbnail: %{url: media.poster_url}
    }
  end
end
```

## Plugin Discovery & Registration

### Discovery Mechanism

Unlike hooks (which scan directories), plugins are **explicitly registered** in the application configuration:

```elixir
# config/runtime.exs

config :mydia, :plugins,
  notification: [
    Mydia.Plugins.Notifications.Ntfy,
    Mydia.Plugins.Notifications.Pushover,
    Mydia.Plugins.Notifications.Telegram
  ],
  enrichment: [
    Mydia.Plugins.Enrichment.AniList,
    Mydia.Plugins.Enrichment.Fanart
  ],
  webhook: [
    Mydia.Plugins.Webhooks.Discord,
    Mydia.Plugins.Webhooks.Slack
  ]
```

### Plugin Manager

```elixir
defmodule Mydia.Plugins.Manager do
  use GenServer
  require Logger

  @doc """
  Start the plugin manager.
  Discovers and registers all configured plugins on startup.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    plugins = discover_plugins()
    validate_plugins(plugins)

    :ets.new(:mydia_plugins, [:named_table, :public, read_concurrency: true])
    :ets.insert(:mydia_plugins, {:plugins, plugins})

    Logger.info("Loaded #{map_size(plugins)} plugin types")
    {:ok, %{plugins: plugins}}
  end

  @doc """
  Get all plugins of a specific type.
  """
  def list_plugins(type) do
    case :ets.lookup(:mydia_plugins, :plugins) do
      [{:plugins, plugins}] -> Map.get(plugins, type, [])
      [] -> []
    end
  end

  @doc """
  Get enabled plugins of a specific type based on user config.
  """
  def enabled_plugins(type) do
    config = Mydia.Config.get()

    list_plugins(type)
    |> Enum.filter(fn plugin_module ->
      plugin_config = get_plugin_config(config, plugin_module)
      Map.get(plugin_config, :enabled, false)
    end)
  end

  # Private

  defp discover_plugins do
    Application.get_env(:mydia, :plugins, %{})
    |> Enum.into(%{}, fn {type, modules} ->
      {type, Enum.map(modules, &load_plugin_info/1)}
    end)
  end

  defp load_plugin_info(module) do
    info = module.plugin_info()
    %{
      module: module,
      name: info.name,
      description: info.description,
      version: info.version,
      config_schema: info.config_schema
    }
  end

  defp validate_plugins(plugins) do
    # Ensure all plugins implement their required behaviours
    Enum.each(plugins, fn {type, plugin_list} ->
      behaviour = behaviour_for_type(type)

      Enum.each(plugin_list, fn %{module: mod} ->
        unless behaviour in (mod.module_info(:attributes)[:behaviour] || []) do
          raise "Plugin #{mod} does not implement #{behaviour}"
        end
      end)
    end)
  end

  defp behaviour_for_type(:notification), do: Mydia.Plugins.Notification
  defp behaviour_for_type(:enrichment), do: Mydia.Plugins.Enrichment
  defp behaviour_for_type(:webhook), do: Mydia.Plugins.Webhook

  defp get_plugin_config(config, plugin_module) do
    # Extract plugin config from main config based on plugin name
    plugin_name = plugin_module.plugin_info().name |> String.downcase()
    get_in(config, [:plugins, String.to_atom(plugin_name)]) || %{}
  end
end
```

### Plugin Executor

```elixir
defmodule Mydia.Plugins.Executor do
  require Logger

  @doc """
  Execute all enabled plugins of the given type for an event.
  Runs asynchronously by default to avoid blocking.
  """
  def execute_async(plugin_type, event, event_data, opts \\ []) do
    Task.start(fn ->
      execute_sync(plugin_type, event, event_data, opts)
    end)
  end

  @doc """
  Execute all enabled plugins synchronously.
  Used when you need to wait for plugin results.
  """
  def execute_sync(plugin_type, event, event_data, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 10_000)
    config = Mydia.Config.get()

    Mydia.Plugins.Manager.enabled_plugins(plugin_type)
    |> Enum.map(fn plugin_info ->
      Task.async(fn ->
        execute_plugin(plugin_type, plugin_info, event, event_data, config, timeout)
      end)
    end)
    |> Enum.map(&Task.await(&1, timeout))
    |> Enum.reject(&match?({:error, _}, &1))
  end

  defp execute_plugin(type, plugin_info, event, event_data, config, timeout) do
    module = plugin_info.module
    plugin_config = get_plugin_config(config, module)

    task = Task.async(fn ->
      case type do
        :notification ->
          module.notify(event, event_data, plugin_config)
        :webhook ->
          module.send_webhook(event, event_data, plugin_config)
        :enrichment ->
          module.enrich(event_data, plugin_config)
      end
    end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        Logger.debug("[Plugin:#{module}] Executed successfully")
        result

      nil ->
        Logger.warning("[Plugin:#{module}] Timeout after #{timeout}ms")
        {:error, :timeout}
    end
  rescue
    error ->
      Logger.error("[Plugin:#{module}] Error: #{inspect(error)}")
      {:error, error}
  end

  defp get_plugin_config(config, plugin_module) do
    plugin_name = plugin_module.plugin_info().name |> String.downcase()
    get_in(config, [:plugins, String.to_atom(plugin_name)]) || %{}
  end
end
```

## Configuration Schema

### Database Schema Extension

```elixir
# lib/mydia/config/schema.ex

embeds_one :plugins, Plugins, on_replace: :update, primary_key: false do
  # Ntfy configuration
  embeds_one :ntfy, Ntfy, on_replace: :update, primary_key: false do
    field :enabled, :boolean, default: false
    field :server_url, :string, default: "https://ntfy.sh"
    field :topic, :string
    field :priority, :integer, default: 3
    field :tags, {:array, :string}, default: []
    field :auth_token, :string

    # Event subscriptions (which events to send)
    field :events, {:array, :string}, default: [
      "after_media_added",
      "on_download_completed",
      "after_import_completed"
    ]
  end

  # Discord webhook configuration
  embeds_one :discord, Discord, on_replace: :update, primary_key: false do
    field :enabled, :boolean, default: false
    field :webhook_url, :string
    field :username, :string, default: "Mydia"
    field :events, {:array, :string}, default: []
  end

  # AniList enrichment
  embeds_one :anilist, AniList, on_replace: :update, primary_key: false do
    field :enabled, :boolean, default: false
    field :prefer_over_tmdb, :boolean, default: false
  end
end
```

### YAML Configuration

```yaml
# config.yaml

plugins:
  ntfy:
    enabled: true
    server_url: "https://ntfy.sh"  # Or self-hosted: "https://ntfy.example.com"
    topic: "mydia-notifications"
    priority: 3
    tags:
      - "tv"
      - "movie"
    # auth_token: "tk_xxxxx"  # Optional for private topics
    events:
      - after_media_added
      - on_download_completed
      - after_import_completed
      - on_import_failed

  discord:
    enabled: false
    webhook_url: "https://discord.com/api/webhooks/..."
    username: "Mydia"
    events:
      - after_media_added
      - on_download_completed

  anilist:
    enabled: true
    prefer_over_tmdb: false  # Use AniList data as fallback, not primary
```

## Integration Points

### Where Plugins Are Called

Plugins are invoked at the **end** of hook execution, ensuring hooks can modify data before plugins receive it:

```elixir
defmodule Mydia.Media do
  alias Mydia.Hooks
  alias Mydia.Plugins.Executor

  def create_media_item(attrs) do
    with {:ok, media_item} <- insert_media_item(attrs) do
      # 1. Execute hooks (synchronous, can modify data)
      {:ok, final_data} = Hooks.execute("after_media_added", %{
        media_item: media_item,
        context: %{user_id: attrs.user_id}
      })

      # Apply hook modifications
      media_item = apply_hook_changes(media_item, final_data)

      # 2. Execute plugins (async, notifications only)
      Executor.execute_async(:notification, "after_media_added", %{
        media_item: media_item
      })

      {:ok, media_item}
    end
  end
end
```

### Event Flow Diagram

```
User Action (Add Media)
        ↓
┌───────────────────┐
│  Business Logic   │ ← Core application code
└───────────────────┘
        ↓
┌───────────────────┐
│   Execute Hooks   │ ← Synchronous, can modify data
│  (Lua Scripts)    │
└───────────────────┘
        ↓
  Apply Changes
        ↓
┌───────────────────┐
│ Execute Plugins   │ ← Async, send notifications
│  (Notifications)  │
└───────────────────┘
        ↓
   Return Result
```

## Plugin Development Guide

### Creating a New Notification Plugin

**Step 1: Create the module**

```elixir
# lib/mydia/plugins/notifications/pushover.ex

defmodule Mydia.Plugins.Notifications.Pushover do
  @behaviour Mydia.Plugins.Notification

  @impl true
  def plugin_info do
    %{
      name: "Pushover",
      description: "Send push notifications via Pushover",
      version: "1.0.0",
      config_schema: %{
        enabled: :boolean,
        user_key: :string,
        api_token: :string,
        priority: :integer
      }
    }
  end

  @impl true
  def test_connection(config) do
    # Test API credentials
    case Req.post("https://api.pushover.net/1/users/validate.json",
      form: [user: config.user_key, token: config.api_token]) do
      {:ok, %{status: 200}} -> {:ok, %{status: "valid"}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def notify(event, event_data, config) do
    unless config.enabled, do: return {:ok, %{skipped: true}}

    message = format_message(event, event_data)

    Req.post("https://api.pushover.net/1/messages.json",
      form: [
        user: config.user_key,
        token: config.api_token,
        message: message,
        priority: config.priority || 0
      ]
    )
  end

  defp format_message(event, data) do
    # Format message based on event type
  end
end
```

**Step 2: Register in config**

```elixir
# config/runtime.exs

config :mydia, :plugins,
  notification: [
    Mydia.Plugins.Notifications.Ntfy,
    Mydia.Plugins.Notifications.Pushover  # Add here
  ]
```

**Step 3: Add schema**

```elixir
# lib/mydia/config/schema.ex

embeds_one :pushover, Pushover, on_replace: :update do
  field :enabled, :boolean, default: false
  field :user_key, :string
  field :api_token, :string
  field :priority, :integer, default: 0
  field :events, {:array, :string}, default: []
end
```

**Step 4: Configure in YAML**

```yaml
plugins:
  pushover:
    enabled: true
    user_key: "xxxxx"
    api_token: "xxxxx"
    priority: 0
    events:
      - after_media_added
```

## Testing Strategy

### Plugin Tests

```elixir
# test/mydia/plugins/notifications/ntfy_test.exs

defmodule Mydia.Plugins.Notifications.NtfyTest do
  use Mydia.DataCase, async: false

  alias Mydia.Plugins.Notifications.Ntfy

  @config %{
    enabled: true,
    server_url: "https://ntfy.sh",
    topic: "test-topic",
    priority: 3
  }

  describe "test_connection/1" do
    test "returns ok when server is reachable" do
      # Mock HTTP request
      assert {:ok, %{status: "connected"}} = Ntfy.test_connection(@config)
    end

    test "returns error when server is unreachable" do
      config = %{@config | server_url: "https://invalid.example.com"}
      assert {:error, _} = Ntfy.test_connection(config)
    end
  end

  describe "notify/3" do
    test "sends notification for media added event" do
      event_data = %{
        media_item: %{title: "Test Movie", year: 2024}
      }

      assert {:ok, %{sent: true}} = Ntfy.notify("after_media_added", event_data, @config)
    end

    test "skips when disabled" do
      config = %{@config | enabled: false}
      assert {:ok, %{skipped: true}} = Ntfy.notify("after_media_added", %{}, config)
    end
  end
end
```

### Integration Tests

```elixir
# test/mydia/plugins/executor_test.exs

defmodule Mydia.Plugins.ExecutorTest do
  use Mydia.DataCase, async: false

  alias Mydia.Plugins.Executor

  setup do
    # Setup test config with plugins enabled
    :ok
  end

  test "executes all enabled notification plugins" do
    event_data = %{media_item: %{title: "Test", year: 2024}}

    results = Executor.execute_sync(:notification, "after_media_added", event_data)

    assert is_list(results)
    assert Enum.all?(results, &match?({:ok, _}, &1))
  end

  test "handles plugin timeout gracefully" do
    # Test timeout handling
  end

  test "handles plugin errors without failing other plugins" do
    # Test error isolation
  end
end
```

## Migration Path

### Phase 1: Core Infrastructure ✅ (Current State)

- [x] Hooks system implemented
- [x] Lua executor working
- [x] Event definitions documented
- [x] Configuration schema exists

### Phase 2: Plugin Framework (Next)

1. **Create plugin behaviours**
   - `Mydia.Plugins.Notification`
   - `Mydia.Plugins.Webhook`
   - `Mydia.Plugins.Enrichment`

2. **Implement Plugin Manager**
   - Discovery and registration
   - ETS storage
   - Validation

3. **Implement Plugin Executor**
   - Async execution
   - Timeout handling
   - Error isolation

4. **Add configuration schema**
   - Extend `config/schema.ex`
   - Support plugin configs in YAML

### Phase 3: Reference Implementation (Ntfy)

1. **Implement Ntfy plugin**
   - Connection testing
   - Notification sending
   - Message formatting

2. **Add integration points**
   - Wire up `after_media_added`
   - Wire up `on_download_completed`
   - Wire up `after_import_completed`

3. **Testing**
   - Unit tests for Ntfy plugin
   - Integration tests for executor
   - Manual testing with real ntfy server

### Phase 4: Additional Plugins

1. **Discord webhook plugin**
2. **Telegram bot plugin**
3. **Slack webhook plugin**
4. **AniList enrichment plugin**

### Phase 5: UI Integration

1. **Plugin management UI**
   - List installed plugins
   - Enable/disable plugins
   - Test connections
   - Configure plugin settings

2. **Plugin marketplace** (future)
   - Browse available plugins
   - Install from registry
   - Update plugins

## Best Practices

### For Plugin Developers

1. **Always implement the required behaviour**: Don't skip callbacks
2. **Fail gracefully**: Return `{:error, reason}` instead of raising
3. **Use async-friendly code**: Avoid blocking operations
4. **Respect timeouts**: Don't assume unlimited execution time
5. **Log appropriately**: Use Logger for debugging, not IO.puts
6. **Test thoroughly**: Write unit tests for all callbacks
7. **Document configuration**: Clear descriptions in `plugin_info/0`

### For Core Developers

1. **Call plugins async by default**: Use `execute_async/3` unless you need results
2. **Provide rich event data**: Include all relevant context
3. **Don't rely on plugin success**: Plugins can fail, always have fallbacks
4. **Test without plugins**: Core functionality should work with all plugins disabled
5. **Version plugin APIs**: Use behaviours to enforce contracts

## Security Considerations

1. **API Token Storage**: Store sensitive tokens in config, never in code
2. **Rate Limiting**: Implement per-plugin rate limits for external APIs
3. **Timeout Enforcement**: Always enforce timeouts on plugin execution
4. **Data Sanitization**: Sanitize user data before sending to external services
5. **Error Messages**: Don't leak sensitive info in error messages
6. **HTTPS Only**: Enforce HTTPS for all external communications

## Performance Considerations

1. **Async Execution**: Run plugins asynchronously to avoid blocking
2. **Concurrency**: Execute multiple plugins in parallel using Task.async
3. **Caching**: Cache plugin metadata and connection status
4. **Batching**: For high-volume events, batch notifications
5. **Circuit Breakers**: Disable failing plugins temporarily

## Future Enhancements

1. **Plugin Dependencies**: Allow plugins to depend on other plugins
2. **Plugin Marketplace**: Central registry of community plugins
3. **Dynamic Loading**: Load plugins at runtime without restart
4. **Plugin Sandboxing**: Run untrusted plugins in isolated processes
5. **Plugin Metrics**: Track execution time, success rate, etc.
6. **Plugin Scheduling**: Cron-like scheduled execution
7. **Plugin Webhooks**: Allow external services to trigger plugin actions

## Example: Complete Ntfy Integration

### Configuration

```yaml
# config.yaml
plugins:
  ntfy:
    enabled: true
    server_url: "https://ntfy.sh"
    topic: "mydia-alerts"
    priority: 3
    tags: ["movie", "tv"]
    events:
      - after_media_added
      - on_download_completed
      - on_download_failed
      - after_import_completed
```

### Usage in Application

```elixir
# lib/mydia/media.ex
def create_media_item(attrs) do
  with {:ok, media_item} <- insert_media_item(attrs) do
    # Execute hooks first (sync, can modify)
    {:ok, final_data} = Hooks.execute("after_media_added", %{
      media_item: media_item
    })

    media_item = apply_changes(media_item, final_data)

    # Execute plugins (async, notifications)
    Plugins.Executor.execute_async(:notification, "after_media_added", %{
      media_item: media_item
    })

    {:ok, media_item}
  end
end
```

### Result

When a media item is added:

1. Hooks run synchronously, potentially modifying the media item
2. Changes are saved to database
3. Ntfy plugin sends notification asynchronously
4. User receives push notification on their phone
5. Application continues without blocking

---

## Summary

This plugin system provides:

✅ **Clear separation of concerns**: Hooks for data transformation, plugins for integrations
✅ **Type safety**: Elixir behaviours enforce contracts at compile time
✅ **Reliability**: Fail-soft design, async execution, timeout handling
✅ **Extensibility**: Easy to add new plugins without modifying core
✅ **Developer experience**: Clear patterns, examples, and testing strategies
✅ **Production ready**: Configuration management, error handling, logging

The ntfy plugin serves as a reference implementation demonstrating all best practices for future plugin development.
