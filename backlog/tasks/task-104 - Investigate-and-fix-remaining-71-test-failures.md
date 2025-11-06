---
id: task-104
title: Investigate and fix remaining 71 test failures
status: In Progress
assignee: []
created_date: '2025-11-06 15:45'
updated_date: '2025-11-06 16:21'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After improving SQLite concurrency (reduced from 111 to 71 failures), systematically investigate and fix the remaining test failures. These appear to be actual logic/assertion issues rather than database concurrency problems.

## Test Results
- Total: 809 tests
- Failures: 71
- Skipped: 11
- Time: 103.9 seconds

## Known Failure Categories
1. Quality parser test assertions (codec, audio format expectations)
2. Metadata provider endpoint issues (404 responses)
3. HTTP header deprecation warnings (Req library)
4. Various domain logic test failures

## Related Files
- config/test.exs (SQLite configuration)
- test/test_helper.exs (max_cases: 4)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All quality parser tests pass with correct assertions
- [ ] #2 Metadata provider tests use correct mock endpoints or are properly skipped
- [ ] #3 HTTP header deprecation warnings are resolved
- [ ] #4 Test suite runs with <10 failures
- [ ] #5 No database concurrency errors in test output
<!-- AC:END -->
