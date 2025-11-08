---
id: task-116.2
title: Enhance title normalization and implement stricter year matching
status: Done
assignee: []
created_date: '2025-11-08 02:18'
updated_date: '2025-11-08 03:06'
labels: []
dependencies: []
parent_task_id: task-116
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Improve title comparison to prevent sequel/prequel/spinoff confusion while maintaining flexibility for legitimate matches.

**Enhancements needed**:
1. **Better normalization**: Handle accents, umlauts (ä→ae, ö→oe, ü→ue), punctuation consistently
2. **Stricter year validation**: 
   - Exact year match: high confidence boost
   - ±1 year: medium confidence
   - >1 year difference: significant penalty (prevent sequels)
   - No year in release: apply cautious threshold
3. **Title suffix detection**: Identify sequel markers (II, 2, Part 2, Reloaded, etc.) and penalize if base title matches but suffix differs
4. **Word boundary matching**: Prevent "Alien" matching "Aliens" by checking word boundaries

**Current state**:
- Jaro-Winkler with basic article removal
- Year matching: +0.3 exact, +0.15 ±1, -0.2 mismatch
- 0.8 confidence threshold

**Improvement targets**:
- Reduce false positives for sequels/prequels
- Maintain high recall for legitimate matches
- Configurable thresholds per use case
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Title normalization handles accents and umlauts correctly
- [x] #2 Year difference >1 results in match rejection for similar titles
- [x] #3 Sequel markers (II, 2, Part 2, etc.) are detected and penalized appropriately
- [x] #4 Word boundary checks prevent 'Alien' matching 'Aliens'
- [x] #5 Legitimate variations (e.g., 'The Movie' vs 'Movie, The') still match
- [x] #6 Tests cover edge cases: sequels, prequels, spin-offs, anthology series
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

**Changes made:**

1. **Enhanced Unicode normalization** - Added `normalize_unicode/1` function:
   - German umlauts: ä→ae, ö→oe, ü→ue, ß→ss
   - Accented characters: à/á/â/ã/ä/å→a, è/é/ê/ë→e, ì/í/î/ï→i, etc.
   - Integrated into `normalize_string/1` for consistent title matching
   - Handles international titles correctly (e.g., "Amélie", "Die Fälscher")

2. **Stricter year validation** - Enhanced `calculate_movie_confidence/2`:
   - Exact year match: +0.3 confidence boost
   - ±1 year difference: +0.15 confidence (for legitimate release date variations)
   - >1 year difference: -0.5 penalty (prevents sequels/prequels matching)
   - No year available: -0.1 penalty (encourages complete metadata)

3. **Sequel marker detection** - Added `has_sequel_marker?/1` function:
   - Roman numerals: II, III, IV, V, etc.
   - Numbered sequels: "2", "3", "Part 2", "Chapter 3"
   - Common sequel words: Reloaded, Revolutions, Returns, Resurrection, Rises, Begins, Origins, Revenge, Redemption, Reckoning, Reborn, Awakening, Legacy
   - Series indicators: Quest, Journey, Chronicles, Saga
   - Penalty of -0.4 when only one title has sequel markers (prevents false matches)

4. **Word boundary checking** - Added `word_boundary_substring?/1` function:
   - Detects singular/plural mismatches (e.g., "Alien" vs "Aliens")
   - Applies -0.5 penalty for detected boundary issues
   - Smart filtering: only penalizes short titles (≤2 words) to avoid false positives
   - Prevents legitimate long titles from being rejected (e.g., "Dr. Strangelove" vs full subtitle)

**Test Results:**
- New enhanced tests: 18/18 passing ✓
- Existing TorrentMatcher tests: 19/19 passing ✓
- ID-based matching tests: 16/16 passing ✓
- Total: 53 tests, 0 failures, no regressions

**Key Improvements:**
- Prevents "The Matrix" (1999) from matching "The Matrix Reloaded" (2003)
- Prevents "Alien" (1979) from matching "Aliens" (1986)
- Handles international titles with accents/umlauts
- Maintains high recall for legitimate title variations
- All acceptance criteria met ✓
<!-- SECTION:NOTES:END -->
