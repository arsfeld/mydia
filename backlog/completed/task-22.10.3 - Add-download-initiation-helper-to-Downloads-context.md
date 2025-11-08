---
id: task-22.10.3
title: Add download initiation helper to Downloads context
status: Done
assignee: []
created_date: '2025-11-05 02:48'
updated_date: '2025-11-05 03:18'
labels:
  - downloads
  - integration
dependencies:
  - task-21.1
  - task-21.2
parent_task_id: task-22.10
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement `Mydia.Downloads.initiate_download/2` function that handles the complete workflow of sending a torrent to a download client and creating a Download record.

This function will be shared by:
- Automatic search background jobs (this task)
- UI-triggered downloads (task-29)
- Any future download features

## Scope

Single reusable function that:
- Selects appropriate download client (by priority or explicit choice)
- Calls `Client.add_torrent/3` with the torrent URL
- Creates Download record with all relevant associations
- Returns `{:ok, download}` or `{:error, reason}`

## Implementation

**Function: `Mydia.Downloads.initiate_download/2`**

```elixir
@doc """
Initiates a download from a search result.

Selects download client, adds torrent, creates Download record.

## Arguments
  - search_result: %SearchResult{} with download_url
  - opts: Keyword list with:
    - :media_item_id - Associate with movie/show
    - :episode_id - Associate with episode
    - :client_name - Use specific client (otherwise priority)
    - :category - Client category for organization

Returns {:ok, %Download{}} or {:error, reason}
"""
def initiate_download(search_result, opts \\ [])
```

**Logic:**
1. Get enabled download clients from config
2. Select client (by name if provided, else highest priority)
3. Build client config map
4. Call `Client.add_torrent(adapter, config, download_url)`
5. Create Download record with:
   - title, size, download_url from search_result
   - download_client, download_client_id from response
   - media_item_id, episode_id from opts
   - status: "pending"
6. Broadcast download update via PubSub

**Error handling:**
- No clients configured
- Client offline/unreachable
- Client rejects torrent
- Database error creating record

## Testing

- Test with valid search result and options
- Test client selection (by name, by priority)
- Test with no clients configured
- Test client failure scenarios
- Test Download record creation with associations
- Test PubSub broadcast
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 initiate_download/2 function added to Downloads context
- [x] #2 Selects download client by priority or explicit name
- [x] #3 Calls Client.add_torrent with search result download_url
- [x] #4 Creates Download record with pending status
- [x] #5 Associates download with media_item_id if provided
- [x] #6 Associates download with episode_id if provided
- [x] #7 Broadcasts download update via PubSub
- [x] #8 Returns {:ok, download} on success
- [x] #9 Returns {:error, reason} for all failure cases
- [x] #10 Handles no clients configured gracefully
- [x] #11 Handles client offline gracefully
- [x] #12 Comprehensive tests for all scenarios
<!-- AC:END -->
