---
id: task-23.9
title: >-
  Add comprehensive environment variable and YAML configuration for library
  paths
status: Done
assignee: []
created_date: '2025-11-06 03:14'
updated_date: '2025-11-06 03:20'
labels:
  - configuration
  - library
  - enhancement
  - environment-variables
dependencies: []
parent_task_id: task-23
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, library paths only support basic MOVIES_PATH and TV_PATH environment variables. This task extends the configuration system to support full library path configuration via environment variables and YAML files, matching the pattern used for download_clients and indexers.

## Current Limitations

1. Only two simple env vars: MOVIES_PATH and TV_PATH
2. No way to configure multiple paths of the same type via env vars
3. No way to set library path properties (monitored, scan_interval, quality_profile_id) via env vars or YAML
4. YAML config only supports movies_path and tv_path fields, not a library_paths list

## Required Implementation

### 1. Environment Variables Pattern
Support numbered environment variables similar to download clients:
```
LIBRARY_PATH_1_PATH=/media/movies
LIBRARY_PATH_1_TYPE=movies
LIBRARY_PATH_1_MONITORED=true
LIBRARY_PATH_1_SCAN_INTERVAL=3600
LIBRARY_PATH_1_QUALITY_PROFILE_ID=1

LIBRARY_PATH_2_PATH=/media/tv
LIBRARY_PATH_2_TYPE=series
LIBRARY_PATH_2_MONITORED=true
LIBRARY_PATH_2_SCAN_INTERVAL=3600
```

### 2. YAML Configuration
Add library_paths list to config.yml:
```yaml
media:
  # Legacy simple configuration (keep for backward compatibility)
  movies_path: "/media/movies"
  tv_path: "/media/tv"
  scan_interval_hours: 1

# Advanced library path configuration
library_paths:
  - path: "/media/movies"
    type: movies
    monitored: true
    scan_interval: 3600
    # optional: quality_profile_id
  - path: "/media/tv-shows"
    type: series
    monitored: true
    scan_interval: 3600
  - path: "/media/mixed"
    type: mixed
    monitored: false
    scan_interval: 7200
```

### 3. Configuration Loader Updates
- Add `load_library_paths_env/0` function to `Mydia.Config.Loader`
- Add `library_paths` embed to `Mydia.Config.Schema`
- Merge YAML library_paths with numbered env vars
- Maintain backward compatibility with movies_path/tv_path

### 4. Settings Module Updates
- Update `get_runtime_library_paths/0` to read from schema library_paths
- Keep legacy MOVIES_PATH/TV_PATH support for backward compatibility
- Ensure proper merging with database records

## Benefits

- **Consistency**: Matches download_clients and indexers configuration pattern
- **Flexibility**: Support multiple library paths of any type via env vars
- **Full control**: Configure all library path properties without using the UI
- **Docker-friendly**: Perfect for container deployments with env vars
- **GitOps-ready**: Full YAML configuration for version control
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Environment variables support LIBRARY_PATH_<N>_* pattern for all properties
- [x] #2 YAML config supports library_paths list with full property configuration
- [x] #3 Config loader merges YAML + env vars + database records properly
- [x] #4 Legacy MOVIES_PATH and TV_PATH env vars still work for backward compatibility
- [x] #5 Legacy movies_path and tv_path YAML fields still work for backward compatibility
- [x] #6 All library path properties can be configured: path, type, monitored, scan_interval, quality_profile_id
- [x] #7 Startup validation works with new configuration format
- [x] #8 Documentation updated in config.example.yml and .env.example
- [x] #9 Runtime library paths include both legacy and new configuration sources
<!-- AC:END -->
