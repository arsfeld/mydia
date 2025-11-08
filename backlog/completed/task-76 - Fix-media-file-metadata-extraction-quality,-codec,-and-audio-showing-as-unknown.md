---
id: task-76
title: >-
  Fix media file metadata extraction - quality, codec, and audio showing as
  unknown
status: Done
assignee: []
created_date: '2025-11-05 15:35'
updated_date: '2025-11-05 15:57'
labels:
  - bug
  - metadata
  - file-parsing
  - media-files
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Overview
Media files in the library are not properly extracting technical metadata during import. Currently, most files show "Unknown" for resolution, codec, audio codec, and other technical details that should be populated from the actual file analysis.

## Current Problem
When viewing media files on the media detail page (task-75's new card layout), the technical information displays:
- **Resolution/Quality**: "Unknown" instead of actual resolution (1080p, 720p, 4K, etc.)
- **Codec**: "Unknown" or "—" instead of video codec (H.264, H.265/HEVC, AV1, etc.)
- **Audio Codec**: "Unknown" or "—" instead of audio codec (AAC, AC3, DTS, etc.)
- **Other metadata**: May be missing HDR format, bitrate, etc.

## Root Cause Investigation Needed
Need to investigate:
1. **File parsing during import**: Check `Mydia.Library.FileParser` module
2. **Metadata extraction**: Verify if FFprobe/MediaInfo integration exists
3. **Database persistence**: Confirm metadata is being saved to media_files table
4. **Data flow**: Trace from file discovery → parsing → database → display

## Proposed Solution
1. **Implement/Fix File Analysis**:
   - Use FFprobe or MediaInfo to extract file metadata
   - Parse video stream info (codec, resolution, bitrate, HDR)
   - Parse audio stream info (codec, channels, bitrate)
   - Extract file size accurately

2. **Update FileParser Module**:
   - Add or fix metadata extraction logic
   - Ensure proper error handling for corrupted/incomplete files
   - Support common video formats (MKV, MP4, AVI, etc.)

3. **Database Schema Verification**:
   - Verify media_files table has all required columns
   - Add migration if columns are missing
   - Ensure proper data types (string for codec, integer for resolution height, etc.)

4. **Re-scan Existing Files**:
   - May need to add a "Refresh File Metadata" feature
   - Or automatically refresh on next library scan
   - Provide UI feedback during metadata refresh

## Technical Considerations
- **Performance**: FFprobe calls can be slow, consider async processing
- **Error handling**: Files may be inaccessible, corrupted, or unsupported
- **Caching**: Don't re-analyze files unnecessarily
- **Verification**: Update verified_at timestamp after successful analysis

## Expected Behavior
After fix, media file cards should display:
- Resolution: "1080p", "720p", "2160p", "4K", etc.
- Codec: "H.264", "HEVC", "AV1", "VP9", etc.
- Audio: "AAC 5.1", "AC3", "DTS-HD MA", "FLAC", etc.
- Size: Accurate file size in GB/MB

## Files to Investigate
- `lib/mydia/library/file_parser.ex` - File metadata extraction
- `lib/mydia/jobs/media_import.ex` - Import job that processes files
- `lib/mydia/media/media_file.ex` - Schema definition
- Database migration files - Check media_files table schema

## Related
- Builds on task-75 (new media files card layout)
- Essential for quality profile matching and release comparisons
- Affects automatic download decisions
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Media files display actual resolution (1080p, 720p, 4K) instead of 'Unknown'
- [x] #2 Video codec information correctly extracted and displayed (H.264, HEVC, etc.)
- [x] #3 Audio codec information correctly extracted and displayed (AAC, AC3, DTS, etc.)
- [x] #4 File size accurately calculated and displayed
- [x] #5 Existing media files can be re-scanned to update metadata
- [x] #6 New files imported automatically extract all metadata
- [x] #7 Error handling for corrupted or inaccessible files
- [x] #8 Metadata extraction performance is acceptable (doesn't block imports)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully implemented comprehensive file metadata extraction using BOTH filename parsing AND FFprobe analysis for media files in the library.

### Changes Made

1. **Created `Mydia.Library.FileAnalyzer` module** (`lib/mydia/library/file_analyzer.ex`):
   - Integrates with FFprobe to extract technical metadata from video files
   - Extracts resolution (1080p, 720p, 4K, etc.) based on video height
   - Identifies video codecs (H.264, HEVC, AV1, VP9, etc.) with profile information
   - Identifies audio codecs (AAC, AC3, DTS, TrueHD, etc.) with channel information
   - Detects HDR formats (Dolby Vision, HDR10+, HDR10, HLG)
   - Extracts bitrate information
   - Handles errors gracefully when FFprobe fails or files are corrupted

2. **Updated `Mydia.Jobs.MediaImport`** (`lib/mydia/jobs/media_import.ex`):
   - Modified `create_media_file_record/3` to use BOTH filename parsing AND FFprobe
   - First parses filename using existing `FileParser` module for baseline metadata
   - Then analyzes actual file with `FileAnalyzer` (FFprobe) for accurate technical data
   - Merges both sources: prefers actual file metadata, falls back to filename metadata
   - Also stores source (BluRay, WEB-DL, etc.) and release_group in metadata field
   - Comprehensive logging for debugging

3. **Enhanced `Mydia.Library` context** (`lib/mydia/library.ex`):
   - Added `refresh_file_metadata/1` to re-analyze a single media file
   - Added `refresh_file_metadata_by_id/1` for convenience
   - Added `refresh_all_file_metadata/0` to bulk refresh all files in library
   - All refresh functions use both filename parsing and FFprobe analysis
   - All refresh functions update the `verified_at` timestamp
   - Comprehensive error handling and logging

4. **Created tests** (`test/mydia/library/file_analyzer_test.exs`):
   - Basic tests for error handling (file not found, FFprobe failures)
   - Documented expected behavior for resolution, codec, and HDR detection
   - Note: Full integration tests require actual video files and FFprobe installation

### Dual-Source Metadata Strategy

The implementation uses a smart fallback strategy:

1. **Filename Parsing** (Primary Fallback):
   - Uses existing `FileParser` module to extract metadata from filename
   - Captures resolution, codec, audio, HDR format, source (BluRay/WEB), release group
   - Always succeeds, providing baseline metadata even when FFprobe fails

2. **FFprobe Analysis** (Preferred Source):
   - Analyzes actual file streams for accurate technical information
   - Provides real resolution, bitrate, codec profiles, channel counts
   - More reliable than filename which can be mislabeled

3. **Merging Strategy**:
   ```elixir
   resolution: file_metadata.resolution || filename_metadata.quality.resolution
   codec: file_metadata.codec || filename_metadata.quality.codec
   audio_codec: file_metadata.audio_codec || filename_metadata.quality.audio
   hdr_format: file_metadata.hdr_format || filename_metadata.quality.hdr_format
   ```

This ensures:
- ✅ Best case: Accurate metadata from actual file analysis
- ✅ Fallback: Metadata from filename if FFprobe unavailable/fails
- ✅ No import failures: Files always get some metadata
- ✅ Additional info: Source and release group from filename stored in metadata field

### Technical Details

- **FFprobe Integration**: Uses JSON output format for reliable parsing
- **Resolution Detection**: Maps video height to standard quality labels
- **Codec Mapping**: Comprehensive mapping of FFprobe codec names to user-friendly names
- **Audio Channels**: Formats channel count as user-friendly strings (Stereo, 5.1, 7.1, etc.)
- **HDR Detection**: Checks color transfer characteristics and side data for HDR formats
- **Error Resilience**: All analysis failures are logged but don't block import operations
- **Filename Fallback**: Always provides baseline metadata even when FFprobe fails

### Usage

**For new imports**: Metadata is automatically extracted from both sources when files are imported.

**For existing files**: Use the Library context functions:
```elixir
# Refresh a single file
Mydia.Library.refresh_file_metadata_by_id(file_id)

# Refresh all files
Mydia.Library.refresh_all_file_metadata()
```

### Requirements

- **Filename parsing**: Always works, no dependencies
- **FFprobe**: Optional but recommended for accurate metadata
  - Part of FFmpeg package
  - If not installed, falls back to filename parsing only

### Future Enhancements

- Add a UI button to trigger metadata refresh for individual files or media items
- Create a background job to automatically refresh files missing metadata
- Add support for parsing subtitle streams
- Cache FFprobe results to avoid re-analyzing unchanged files
- Add comparison view showing filename vs actual file metadata
<!-- SECTION:NOTES:END -->
