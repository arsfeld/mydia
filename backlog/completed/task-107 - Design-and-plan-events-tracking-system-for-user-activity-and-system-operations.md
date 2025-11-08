---
id: task-107
title: Design and plan events tracking system for user activity and system operations
status: Done
assignee: []
created_date: '2025-11-06 18:26'
updated_date: '2025-11-06 18:42'
labels:
  - enhancement
  - architecture
  - planning
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Problem

Currently, the application lacks a centralized way to track important events and user activity. Information like torrent searches, downloads initiated, media additions, and other operations are scattered or not tracked at all. This makes it difficult to:

- Understand user behavior and application usage patterns
- Debug issues by tracing what happened when
- Provide activity history to users
- Generate analytics and insights
- Audit system operations

## Proposed Solution

Design and implement a comprehensive events tracking system that captures key application events in a structured, queryable format.

## Events to Track

**Media Management:**
- `media_item.added` - New movie/show added to library
- `media_item.updated` - Metadata refreshed
- `media_item.removed` - Item removed from library
- `episode.monitored` - Episode monitoring status changed

**Search & Downloads:**
- `search.performed` - User searched for releases
- `search.automatic` - Automatic search triggered
- `download.initiated` - Torrent added to client
- `download.completed` - Download finished
- `download.failed` - Download encountered error
- `download.cancelled` - User cancelled download

**System Operations:**
- `indexer.health_check` - Indexer health status changed
- `download_client.health_check` - Client health status changed
- `background_job.executed` - Scheduled job ran

**User Actions:**
- `user.login` - User authenticated
- `settings.changed` - Configuration updated

## Design Considerations

1. **Schema Design:**
   - Event type/category
   - Timestamp (with timezone)
   - Actor (user_id or "system")
   - Resource (media_item_id, download_id, etc.)
   - Metadata (JSON payload with event-specific details)
   - Searchable/filterable fields

2. **Storage:**
   - Separate `events` table
   - Indexed for efficient querying
   - Retention policy (how long to keep events)
   - Partitioning strategy for large datasets

3. **API:**
   - Simple event creation interface
   - Event querying with filters
   - Real-time event streaming (Phoenix PubSub)

4. **UI:**
   - Activity feed/timeline view
   - Filtering by event type, date range, resource
   - User-specific activity view
   - System-wide activity dashboard

5. **Integration:**
   - Add event tracking to existing operations
   - Non-blocking (don't fail operations if event logging fails)
   - Background processing for expensive operations

## Out of Scope (for initial implementation)

- Event replay/sourcing for state reconstruction
- Complex analytics and reporting
- Event-driven architecture (events as triggers)

## Success Criteria

- Clear event schema designed and documented
- Database table created with appropriate indexes
- Core events integrated into application flow
- Basic activity view in UI
- Performance impact is negligible

## Related

This task should be completed before or alongside task to separate download client state from historical records, as the events system will capture download history.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Design document includes complete database schema with all fields and indexes
- [ ] #2 Event type taxonomy defined with categories and specific event types
- [ ] #3 Ecto schema structure documented with all fields and validations
- [ ] #4 Events context API designed with CRUD operations and filtering
- [ ] #5 Integration strategy documented for Media, Downloads, and Jobs contexts
- [ ] #6 Retention/cleanup strategy designed with Oban job
- [ ] #7 UI component design outlined for activity feeds
- [ ] #8 Performance considerations and non-blocking strategies documented
- [ ] #9 Testing strategy defined with unit and integration test examples
- [ ] #10 Migration roadmap provided with implementation phases
- [ ] #11 Relationship to existing hooks system clarified
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Events Tracking System - Implementation Plan

### Overview

Design a centralized event tracking system to capture important application activities, user actions, and system operations. This will provide audit trails, debugging context, and usage insights.

### System Architecture

#### 1. Core Components

- **Events Context** (`Mydia.Events`) - Main API for creating and querying events
- **Event Schema** (`Mydia.Events.Event`) - Database schema for events
- **Event Types Module** - Centralized event type definitions
- **PubSub Integration** - Real-time event streaming to LiveViews
- **Background Worker** - Event cleanup/retention (Oban job)

#### 2. Relationship to Existing Systems

**Hooks System (Existing):**
- Purpose: User-defined extensibility via Lua scripts
- Triggered by: Lifecycle events (e.g., after_media_added)
- Events system can trigger hooks OR hooks can create events

**Events System (New):**
- Purpose: Internal audit trail and activity history
- Captured by: Application code at key operations
- Used for: UI activity feeds, debugging, analytics

**Integration Strategy:**
Events and hooks are complementary:
```elixir
# Option 1: Events trigger hooks
Events.create_event("media_item.added", ...) 
# -> PubSub broadcast 
# -> Hook listener creates Lua hook execution

# Option 2: Keep separate (recommended for v1)
Media.create_media_item(...) do
  Events.create_event("media_item.added", ...)  # For tracking
  Hooks.execute_async("after_media_added", ...) # For user extensibility
end
```

### Database Schema

#### Events Table

```sql
CREATE TABLE events (
  id TEXT PRIMARY KEY NOT NULL,
  event_type TEXT NOT NULL,
  category TEXT NOT NULL,
  actor_type TEXT NOT NULL CHECK(actor_type IN ('user', 'system', 'job')),
  actor_id TEXT,  -- user_id for user actions, job name for jobs, null for system
  
  -- Resource associations (nullable, at least one should be set for most events)
  resource_type TEXT,  -- 'media_item', 'episode', 'download', etc.
  resource_id TEXT,
  
  -- Secondary resource (e.g., episode within media_item)
  secondary_resource_type TEXT,
  secondary_resource_id TEXT,
  
  -- Event metadata (JSON)
  metadata TEXT,  -- Flexible data specific to event type
  
  -- Searchable fields extracted from metadata for common queries
  status TEXT,  -- For state changes (e.g., "completed", "failed")
  severity TEXT CHECK(severity IS NULL OR severity IN ('info', 'warning', 'error')),
  
  inserted_at TEXT NOT NULL
)

CREATE INDEX events_type_idx ON events(event_type)
CREATE INDEX events_category_idx ON events(category)
CREATE INDEX events_actor_idx ON events(actor_type, actor_id)
CREATE INDEX events_resource_idx ON events(resource_type, resource_id)
CREATE INDEX events_inserted_at_idx ON events(inserted_at DESC)
CREATE INDEX events_composite_idx ON events(category, event_type, inserted_at DESC)
```

#### Schema Design Rationale

1. **event_type**: Specific event identifier (e.g., "media_item.added", "download.completed")
2. **category**: High-level grouping (e.g., "media", "downloads", "search", "system")
3. **actor_type + actor_id**: Who/what triggered the event
4. **resource_type + resource_id**: Primary entity affected
5. **secondary_resource_***: For nested relationships (episode within media_item)
6. **metadata**: Flexible JSON for event-specific data
7. **status/severity**: Extracted fields for common filtering

### Event Type Taxonomy

#### Categories and Types

**Media Management** (category: "media")
- `media_item.added` - New movie/show added
- `media_item.updated` - Metadata refreshed
- `media_item.removed` - Item removed
- `media_item.monitored_changed` - Monitoring toggled
- `episode.monitored_changed` - Episode monitoring changed
- `season.monitored_changed` - Season monitoring batch update

**Search & Downloads** (category: "downloads")
- `search.manual` - User performed search
- `search.automatic` - Background search triggered
- `download.initiated` - Torrent added to client
- `download.completed` - Download finished
- `download.failed` - Download encountered error
- `download.cancelled` - User cancelled download
- `download.paused` - Download paused
- `download.resumed` - Download resumed

**Library & Files** (category: "library")
- `library.scan_started` - Library scan initiated
- `library.scan_completed` - Scan finished
- `library.file_imported` - Media file matched and imported
- `library.file_renamed` - File renamed by system

**System Operations** (category: "system")
- `indexer.health_changed` - Indexer health status changed
- `download_client.health_changed` - Client health changed
- `job.executed` - Background job ran
- `job.failed` - Background job failed

**User Actions** (category: "auth")
- `user.login` - User authenticated
- `user.logout` - User logged out
- `settings.changed` - Configuration updated

### Event Schema (Ecto)

```elixir
defmodule Mydia.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "events" do
    field :event_type, :string
    field :category, :string
    field :actor_type, Ecto.Enum, values: [:user, :system, :job]
    field :actor_id, :string
    
    field :resource_type, :string
    field :resource_id, :string
    field :secondary_resource_type, :string
    field :secondary_resource_id, :string
    
    field :metadata, :map
    field :status, :string
    field :severity, Ecto.Enum, values: [:info, :warning, :error]
    
    field :inserted_at, :utc_datetime
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_type, :category, :actor_type, :actor_id,
      :resource_type, :resource_id,
      :secondary_resource_type, :secondary_resource_id,
      :metadata, :status, :severity
    ])
    |> validate_required([:event_type, :category, :actor_type])
    |> put_timestamp()
  end

  defp put_timestamp(changeset) do
    put_change(changeset, :inserted_at, DateTime.utc_now())
  end
end
```

### Events Context API

```elixir
defmodule Mydia.Events do
  @moduledoc """
  The Events context handles event tracking and activity history.
  """

  alias Mydia.Events.Event
  alias Mydia.Repo
  import Ecto.Query

  @doc """
  Creates an event.
  
  ## Examples
  
      Events.create_event(%{
        event_type: "media_item.added",
        category: "media",
        actor_type: :user,
        actor_id: user_id,
        resource_type: "media_item",
        resource_id: media_item.id,
        metadata: %{title: media_item.title, type: media_item.type}
      })
  """
  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, event} = result ->
        broadcast_event(event)
        result
      error ->
        error
    end
  end

  @doc """
  Creates an event, logging errors but not failing.
  
  Use this in critical paths where event creation should never
  fail the primary operation.
  """
  def create_event_async(attrs) do
    Task.start(fn ->
      case create_event(attrs) do
        {:ok, _event} -> :ok
        {:error, reason} ->
          Logger.warning("Failed to create event: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Lists events with filtering and pagination.
  
  ## Options
  - `:category` - Filter by category
  - `:event_type` - Filter by specific type
  - `:actor_type` - Filter by actor type
  - `:actor_id` - Filter by specific actor
  - `:resource_type` - Filter by resource type
  - `:resource_id` - Filter by specific resource
  - `:severity` - Filter by severity
  - `:limit` - Max results (default: 100)
  - `:offset` - Pagination offset
  - `:since` - Only events after this datetime
  """
  def list_events(opts \\ []) do
    Event
    |> apply_filters(opts)
    |> limit(^Keyword.get(opts, :limit, 100))
    |> offset(^Keyword.get(opts, :offset, 0))
    |> order_by([e], desc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets events for a specific resource (e.g., all events for a media item).
  """
  def get_resource_events(resource_type, resource_id, opts \\ []) do
    list_events(
      Keyword.merge(opts, [
        resource_type: resource_type,
        resource_id: resource_id
      ])
    )
  end

  @doc """
  Counts events matching filters.
  """
  def count_events(opts \\ []) do
    Event
    |> apply_filters(opts)
    |> Repo.aggregate(:count)
  end

  @doc """
  Deletes events older than the specified duration.
  
  ## Examples
      
      # Delete events older than 90 days
      Events.delete_old_events(days: 90)
  """
  def delete_old_events(opts) do
    cutoff = calculate_cutoff_date(opts)
    
    Event
    |> where([e], e.inserted_at < ^cutoff)
    |> Repo.delete_all()
  end

  # Helper functions for event creation
  
  def media_item_added(media_item, actor_type \\ :system, actor_id \\ nil) do
    create_event_async(%{
      event_type: "media_item.added",
      category: "media",
      actor_type: actor_type,
      actor_id: actor_id,
      resource_type: "media_item",
      resource_id: media_item.id,
      metadata: %{
        title: media_item.title,
        type: media_item.type,
        year: media_item.year,
        tmdb_id: media_item.tmdb_id
      }
    })
  end

  def download_initiated(download, search_result, actor_type \\ :system, actor_id \\ nil) do
    create_event_async(%{
      event_type: "download.initiated",
      category: "downloads",
      actor_type: actor_type,
      actor_id: actor_id,
      resource_type: "download",
      resource_id: download.id,
      secondary_resource_type: if(download.media_item_id, do: "media_item", else: nil),
      secondary_resource_id: download.media_item_id || download.episode_id,
      metadata: %{
        title: download.title,
        indexer: download.indexer,
        quality: search_result.quality,
        size: search_result.size
      }
    })
  end

  # ... more helper functions for common events

  defp broadcast_event(event) do
    Phoenix.PubSub.broadcast(
      Mydia.PubSub,
      "events",
      {:event_created, event}
    )
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:category, category}, q -> where(q, [e], e.category == ^category)
      {:event_type, type}, q -> where(q, [e], e.event_type == ^type)
      {:actor_type, type}, q -> where(q, [e], e.actor_type == ^type)
      {:actor_id, id}, q -> where(q, [e], e.actor_id == ^id)
      {:resource_type, type}, q -> where(q, [e], e.resource_type == ^type)
      {:resource_id, id}, q -> where(q, [e], e.resource_id == ^id)
      {:severity, sev}, q -> where(q, [e], e.severity == ^sev)
      {:since, datetime}, q -> where(q, [e], e.inserted_at >= ^datetime)
      _, q -> q
    end)
  end

  defp calculate_cutoff_date(opts) do
    days = Keyword.get(opts, :days, 90)
    DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)
  end
end
```

### Integration Points

#### 1. Media Context

Add event tracking to key operations:

```elixir
# In Mydia.Media.create_media_item/1
def create_media_item(attrs \\ %{}) do
  with {:ok, media_item} <- ... do
    # Existing hook
    Hooks.execute_async("after_media_added", ...)
    
    # New: Track event
    Events.media_item_added(media_item, :user, get_current_user_id())
    
    {:ok, media_item}
  end
end
```

#### 2. Downloads Context

```elixir
# In Mydia.Downloads.initiate_download/2
def initiate_download(%SearchResult{} = search_result, opts \\ []) do
  with {:ok, download} <- ... do
    Events.download_initiated(download, search_result, :user, get_user_id(opts))
    {:ok, download}
  end
end

# In download monitor job
def handle_completed_download(download) do
  Events.create_event_async(%{
    event_type: "download.completed",
    category: "downloads",
    actor_type: :system,
    resource_type: "download",
    resource_id: download.id,
    status: "completed",
    metadata: %{...}
  })
end
```

#### 3. Background Jobs

```elixir
# In Oban workers
defmodule Mydia.Jobs.MetadataRefresh do
  def perform(%{args: args}) do
    Events.create_event_async(%{
      event_type: "job.executed",
      category: "system",
      actor_type: :job,
      actor_id: "metadata_refresh",
      metadata: %{duration_ms: duration, items_processed: count}
    })
  end
end
```

### Retention Strategy

#### Oban Job for Cleanup

```elixir
defmodule Mydia.Jobs.EventCleanup do
  use Oban.Worker, queue: :maintenance, max_attempts: 3

  @impl Oban.Worker
  def perform(_job) do
    # Get retention days from config (default 90)
    retention_days = Application.get_env(:mydia, :event_retention_days, 90)
    
    case Mydia.Events.delete_old_events(days: retention_days) do
      {count, nil} when count > 0 ->
        Logger.info("Deleted #{count} old events (older than #{retention_days} days)")
        :ok
      _ ->
        :ok
    end
  end
end

# Schedule weekly in application.ex or config
Oban.insert(Mydia.Jobs.EventCleanup.new(%{}, schedule_in: {7, :days}))
```

### UI Components

#### 1. Activity Feed LiveView

```elixir
defmodule MydiaWeb.ActivityLive.Index do
  use MydiaWeb, :live_view
  alias Mydia.Events

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Mydia.PubSub, "events")
    end

    socket =
      socket
      |> assign(:filter_category, "all")
      |> load_events()

    {:ok, socket}
  end

  def handle_event("filter", %{"category" => category}, socket) do
    {:noreply, socket |> assign(:filter_category, category) |> load_events()}
  end

  def handle_info({:event_created, _event}, socket) do
    # Refresh events when new event arrives
    {:noreply, load_events(socket)}
  end

  defp load_events(socket) do
    category = socket.assigns.filter_category
    opts = if category == "all", do: [], else: [category: category]
    
    events = Events.list_events(Keyword.merge(opts, [limit: 50]))
    stream(socket, :events, events, reset: true)
  end
end
```

#### 2. Resource Activity Component

```elixir
# Show events for a specific resource (e.g., media item detail page)
<.live_component
  module={ActivityFeedComponent}
  id="media-activity"
  resource_type="media_item"
  resource_id={@media_item.id}
/>
```

### Performance Considerations

1. **Non-blocking**: Use `create_event_async` in critical paths
2. **Indexes**: Composite indexes on common query patterns
3. **Retention**: Automatic cleanup prevents unbounded growth
4. **PubSub**: Selective subscription (per-resource or global)
5. **Batch Operations**: For bulk updates, create summary event instead of per-item

### Migration Strategy

1. Create events table and indexes
2. Implement Events context with basic CRUD
3. Add helper functions for common event types
4. Integrate into 2-3 high-value operations (media add, download start)
5. Add UI for activity feed
6. Gradually add more event tracking points
7. Implement retention/cleanup job

### Testing Strategy

```elixir
# Unit tests for Events context
test "creates event with required fields" do
  assert {:ok, event} = Events.create_event(%{
    event_type: "test.event",
    category: "test",
    actor_type: :system
  })
  
  assert event.event_type == "test.event"
end

# Integration tests for event creation in contexts
test "creating media item tracks event" do
  {:ok, media_item} = Media.create_media_item(%{...})
  
  events = Events.get_resource_events("media_item", media_item.id)
  assert length(events) == 1
  assert hd(events).event_type == "media_item.added"
end
```

### Out of Scope (Future Enhancements)

1. Event replay for state reconstruction
2. Complex analytics dashboards
3. Event-driven architecture (events as triggers)
4. Webhook notifications based on events
5. Event filtering DSL
6. Event export (CSV, JSON)

### Success Metrics

- [ ] Events table created with proper indexes
- [ ] Events context API implemented and tested
- [ ] 5+ event types integrated into application
- [ ] Activity feed UI shows real-time events
- [ ] Retention policy implemented
- [ ] Performance impact < 5ms per operation
- [ ] Test coverage > 80%
<!-- SECTION:PLAN:END -->
