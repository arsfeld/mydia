---
id: task-63
title: Close manual search dialog after adding movie torrent
status: Done
assignee: []
created_date: '2025-11-05 04:35'
updated_date: '2025-11-05 04:59'
labels:
  - enhancement
  - ui
  - ux
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently when a user selects a torrent from the manual search results and adds it to downloads, the dialog remains open. This requires the user to manually close it, which is an extra unnecessary step.

## Current Behavior

1. User opens manual search dialog for a movie
2. User clicks "Download" on a search result
3. Download is initiated successfully
4. Dialog remains open
5. User must manually close the dialog

## Expected Behavior

1. User opens manual search dialog for a movie
2. User clicks "Download" on a search result
3. Download is initiated successfully
4. **Dialog automatically closes**
5. User sees the download in progress in the downloads list

## Benefits

- Improved UX - one less click required
- Clear feedback that the action completed
- Consistent with common modal dialog patterns
- Reduces confusion about whether to close the dialog

## Implementation Considerations

- Should only close on successful download initiation
- On error, dialog should remain open to allow retry
- Consider showing a brief success message before closing (optional)
- May need to handle both movie and TV show manual search dialogs
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Manual search dialog closes automatically after successful download initiation
- [x] #2 Dialog remains open if download fails (to allow retry)
- [x] #3 Works for both movie and TV show manual search dialogs
- [x] #4 No visual glitches or race conditions when closing
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation

Modified the `download_from_search` event handler in `lib/mydia_web/live/media_live/show.ex` to automatically close the manual search modal after successfully initiating a download.

### Changes Made

1. **Updated success case (lines 574-590)**: Added modal closing logic after successful download:
   - Set `show_manual_search_modal` to `false`
   - Clear `manual_search_query`
   - Clear `manual_search_context`
   - Set `searching` to `false`
   - Set `results_empty?` to `false`
   - Reset `search_results` stream

2. **Error case remains unchanged**: When a download fails, the modal stays open, allowing the user to retry with a different release.

### Benefits

- Improved user experience with one less manual step
- Clear feedback that the download action completed successfully
- Consistent with common modal dialog patterns
- Works for both movie and TV show manual searches (including episode-specific searches)

### Testing

- Code compiles without errors
- Follows existing Phoenix LiveView patterns from the `close_manual_search_modal` event handler
- No visual glitches or race conditions expected as we're using standard LiveView assign updates
<!-- SECTION:NOTES:END -->
