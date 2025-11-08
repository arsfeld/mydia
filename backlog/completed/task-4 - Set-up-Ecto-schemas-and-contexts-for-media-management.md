---
id: task-4
title: Set up Ecto schemas and contexts for media management
status: Done
assignee: []
created_date: '2025-11-04 01:52'
updated_date: '2025-11-04 02:46'
labels:
  - ecto
  - contexts
  - business-logic
dependencies:
  - task-3
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create Ecto schemas for MediaItem, Episode, MediaFile, QualityProfile, Download, User, and ApiKey. Implement Phoenix contexts (Media, Library, Downloads, Accounts, Settings) following bounded context pattern.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All Ecto schemas created with proper field types
- [x] #2 Context modules created for each domain
- [x] #3 Basic CRUD functions implemented in contexts
- [x] #4 Schemas properly preload associations
- [x] #5 Changesets with validations implemented
- [x] #6 Tests written for context functions
<!-- AC:END -->
