---
id: task-114.8
title: Fix remaining test failures
status: To Do
assignee: []
created_date: '2025-11-08 02:06'
updated_date: '2025-11-08 03:27'
labels:
  - testing
  - bug-fix
  - quality
dependencies: []
parent_task_id: '114'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fix all remaining test failures to ensure the test suite passes completely.

## Current Status
- Total failures: 66 (increased from initial 7)
- Fixed: ErrorTest status code issue, HTTPTest headers access issue
- New issues introduced by error handling changes

## Test Failure Categories

### 1. Adapter callback issues (2 failures)
- JackettTest: function_exported?(Jackett, :search, 3) returns false
- ProwlarrTest: function_exported?(Prowlarr, :search, 3) returns false

### 2. MediaImportTest failures (2 failures)
- Expected {:error, :no_client} but got {:ok, :skipped}
- Error handling changed behavior

### 3. Metadata Provider RelayTest failures (~20+ failures)
- Multiple tests failing with {:error, ...} instead of {:ok, ...}
- Likely caused by error message format changes

### 4. Downloads duplicate prevention (1 failure)
- Expected {:error, :duplicate_download} but got {:ok, ...}

### 5. Database/concurrency issues (remaining from before)
- SQLite busy errors
- Connection pool issues

## Root Cause
The error message format change in lib/mydia/metadata/provider/error.ex may have broken tests that depend on specific error message formats or behavior.

## Fix Approach
1. Review the error.ex changes - may need to revert or adjust
2. Fix adapter callback tests
3. Fix MediaImport test expectations
4. Fix Relay test failures
5. Address database concurrency issues
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Test Fixes Completed

### Fixed Issues:
1. **Config.Schema.fetch/2 errors** - Fixed by updating hooks/executor.ex to handle struct field access properly instead of using get_in/2
2. **Quality profile count tests** - Updated from 6 to 8 profiles to account for Remux-1080p and Remux-2160p additions
3. **Indexer UUID handling** - Added UUID support to get_indexer_config!/1 for database lookups

### Test Results:
- Started with: 899 tests, 67 failures
- After fixes: 899 tests, 61 failures (6 tests fixed)
- All Settings tests now passing (22/22)

### Remaining Failures:
Most remaining failures appear to be in:
- MediaImport tests (behavior changed with hardlink implementation)
- Metadata Provider Relay tests (may be API-related or mock-related)
- Some database connection issues in async tests

These failures are not directly related to task 114's REMUX and TRaSH Guides features.

## Progress Update

### Hooks Executor Fix (25 tests fixed!)
- **Issue**: `Config.Schema.fetch/2` undefined function error
- **Root Cause**: Code was trying to access Config.Schema struct (from Ecto) as a map
- **Fix**: Added proper pattern matching for struct type and used struct field access
- **Result**: Test failures reduced from 66 → 41
- **Commit**: fa558d2

### Remaining 41 Failures
Categories:
1. ID-based torrent matching tests (new feature tests - may need implementation)
2. Download/client integration tests (some flaky/external service dependencies)
3. SQLite database busy errors (concurrency issues)
4. HTTP test failures (headers access returning nil)
5. Timeout errors in TV show search tests

Next: Analyze the 41 remaining failures and categorize them by fix priority.
<!-- SECTION:NOTES:END -->
