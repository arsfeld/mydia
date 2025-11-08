---
id: task-22.10.2
title: Implement pluggable release ranking and scoring system
status: Done
assignee:
  - assistant
created_date: '2025-11-05 02:48'
updated_date: '2025-11-05 03:03'
labels:
  - search
  - ranking
  - scoring
dependencies: []
parent_task_id: task-22.10
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create `Mydia.Indexers.ReleaseRanker` module that ranks search results based on configurable criteria. This provides the foundation for selecting the "best" torrent from search results.

## Scope

Build a flexible, extensible ranking system that:
- Scores releases based on seeders, size, quality, age
- Returns ranked results with score breakdowns
- Designed for future expansion (custom rules, quality profiles)
- Can be used by both background jobs and UI

## Implementation

**Module: `lib/mydia/indexers/release_ranker.ex`**

Core functions:
- `select_best_result(results, opts)` - Returns single best match
- `rank_all(results, opts)` - Returns all results with scores
- `filter_acceptable(results, opts)` - Filters by minimum criteria

Scoring factors (private functions):
- Seeders: More is better (diminishing returns after 100)
- Size: Penalize extremes (< 100MB or > 20GB)
- Quality: Prefer based on order (e.g., 1080p > 720p > 2160p)
- Age: Slight preference for newer releases

Options support:
- `:min_seeders` - Minimum required (default: 5)
- `:size_range` - `{min_mb, max_mb}` tuple
- `:preferred_qualities` - List like `["1080p", "720p"]`
- `:blocked_tags` - Filter out results with these tags
- `:preferred_tags` - Boost results with these tags

Score metadata includes breakdown showing why each result scored as it did.

## Testing

- Unit tests for each scoring function
- Test filtering logic (blocked tags, size limits)
- Test ranking with various result sets
- Test that score metadata is correctly generated
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ReleaseRanker module created with core functions
- [x] #2 select_best_result returns best match based on scoring
- [x] #3 rank_all returns all results with scores and metadata
- [x] #4 filter_acceptable removes results that don't meet criteria
- [x] #5 Scoring considers seeders, size, quality, and age
- [x] #6 Options for min_seeders, size_range, preferred_qualities work
- [x] #7 Blocked tags filter out unwanted results
- [x] #8 Score metadata includes breakdown of scoring factors
- [x] #9 Comprehensive unit tests covering all scoring scenarios
- [x] #10 Easy to extend with new scoring rules in the future
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Module Structure
Create `lib/mydia/indexers/release_ranker.ex` with:
- Public API: `select_best_result/2`, `rank_all/2`, `filter_acceptable/2`
- Scoring factors: seeders (logarithmic), size (bell curve), quality (via QualityParser), age
- Options: `:min_seeders`, `:size_range`, `:preferred_qualities`, `:blocked_tags`, `:preferred_tags`
- Score breakdown metadata for transparency

### Implementation Steps
1. Create ReleaseRanker module with core structure and documentation
2. Implement `filter_acceptable/2` with filtering logic (tags, size, seeders)
3. Implement private scoring functions (seeders, size, quality, age)
4. Implement `rank_all/2` with score calculation and metadata
5. Implement `select_best_result/2` using `rank_all/2`
6. Create comprehensive test suite at `test/mydia/indexers/release_ranker_test.exs`
7. Run tests and ensure all pass

### Design Notes
- Pure functions, no state
- Can replace existing `rank_results/1` in `Mydia.Indexers`
- Built on existing `QualityParser.quality_score/1`
- Extensible via clear scoring factors
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

Successfully implemented the ReleaseRanker module with all features:

**Files Created:**
- `lib/mydia/indexers/release_ranker.ex` - Main ranking module (357 lines)
- `test/mydia/indexers/release_ranker_test.exs` - Comprehensive test suite (39 tests, all passing)

**Key Features:**
- Flexible scoring system with 5 factors: quality (60%), seeders (25%), size (10%), age (5%), and tag bonuses
- Configurable filtering: min_seeders, size_range, blocked_tags, preferred_tags
- Quality preference support with automatic boosting
- Score breakdown metadata for transparency
- Pure functional design for easy testing and extension

**Scoring Details:**
- Seeder scoring uses logarithmic scale with cap at 500 to prevent dominance
- Size scoring uses bell curve favoring 2-15GB range
- Quality scoring leverages existing QualityParser with preference boosts
- Age scoring favors recent releases (< 7 days gets highest score)
- Tag system supports both blocking unwanted content and boosting preferred tags

**Test Coverage:**
- All public functions tested
- Each scoring factor tested independently  
- Option combinations tested
- Edge cases handled (nil values, empty lists, etc.)
- Score metadata validation

All 39 tests pass successfully. The module is ready for integration into background search jobs and UI.
<!-- SECTION:NOTES:END -->
