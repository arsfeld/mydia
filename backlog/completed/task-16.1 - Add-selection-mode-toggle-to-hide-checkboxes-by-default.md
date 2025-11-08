---
id: task-16.1
title: Add selection mode toggle to hide checkboxes by default
status: Done
assignee:
  - '@assistant'
created_date: '2025-11-04 21:46'
updated_date: '2025-11-04 21:55'
labels:
  - ui
  - ux
dependencies: []
parent_task_id: '16'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Make the multi-select functionality opt-in rather than always visible. Add a "Select" button in the header that toggles selection mode on/off.

**Current Behavior:**
- Checkboxes are always visible on all media items
- Selection controls always show in header

**Desired Behavior:**
- Checkboxes hidden by default
- "Select" button in header to enter selection mode
- Once in selection mode:
  - Checkboxes become visible
  - "Select All" and "Cancel" buttons appear
  - Floating action toolbar appears when items selected
- Cancel button exits selection mode and clears selection

**UI Changes:**
- Add "Select" button next to view mode toggle
- Show/hide checkboxes based on `:selection_mode` assign
- Replace "Select All" with "Cancel" when in selection mode
- Exit selection mode when:
  - Cancel button clicked
  - Esc pressed
  - After successful batch operation

**Files to modify:**
- `lib/mydia_web/live/media_live/index.ex` - Add selection_mode state and toggle handler
- `lib/mydia_web/live/media_live/index.html.heex` - Conditional checkbox rendering, Select button
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Checkboxes hidden by default
- [x] #2 Select button in header toggles selection mode
- [x] #3 Selection controls only visible in selection mode
- [x] #4 Cancel button exits selection mode
- [x] #5 Esc key exits selection mode
- [x] #6 Batch operations automatically exit selection mode
- [x] #7 Selection cleared when exiting selection mode
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Current State
- Checkboxes always visible on grid cards and list rows
- "Select All" button always visible in header
- No `:selection_mode` assign exists

### Changes

**1. LiveView Module (index.ex)**
- Add `:selection_mode` assign in mount/3 (default: false)
- Add handle_event("toggle_selection_mode") - Enter/exit selection mode
- Modify Esc key handler to exit selection mode AND clear selection
- Modify batch operation handlers to exit selection mode on success

**2. Template (index.html.heex)**
- Header: Replace "Select All" with conditional "Select" or "Select All + Cancel"
- Grid view: Wrap checkbox in `if @selection_mode`
- List view: Wrap checkbox in `if @selection_mode`

### Behavior Flow
1. Default: Checkboxes hidden, "Select" button visible
2. Click "Select": Enter selection mode → checkboxes appear
3. Click "Cancel" or Esc: Exit selection mode → clear selection, hide checkboxes
4. After batch operation: Auto-exit selection mode
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

### Changes Made

**LiveView Module (index.ex)**
- Added `:selection_mode` assign in mount/3 (default: false)
- Added `handle_event("toggle_selection_mode")` - Toggles selection mode on/off, clears selection when exiting
- Updated `handle_event("keydown", %{"key" => "Escape"})` to exit selection mode AND clear selection
- Updated all batch operation handlers to exit selection mode on success:
  - batch_monitor
  - batch_unmonitor
  - batch_delete_confirmed
  - batch_edit_submit

**Template (index.html.heex)**
- Header controls now conditional:
  - When NOT in selection mode: Shows "Select" button only
  - When IN selection mode: Shows "Select All" and "Cancel" buttons
- Grid view checkboxes: Wrapped in `if @selection_mode`
- List view checkboxes: Wrapped in `if @selection_mode`

### Behavior
1. Default state: Checkboxes hidden, "Select" button visible
2. Click "Select": Enter selection mode → checkboxes appear
3. Click "Cancel" or press Esc: Exit selection mode → clear selection, hide checkboxes
4. After any batch operation: Automatically exit selection mode

### Code Quality
- Code follows Phoenix LiveView conventions
- Uses conditional rendering with Elixir if statements
- Clean separation of selection mode state from selection data
- All acceptance criteria met
<!-- SECTION:NOTES:END -->
