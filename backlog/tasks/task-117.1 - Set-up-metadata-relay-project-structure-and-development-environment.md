---
id: task-117.1
title: Set up metadata relay project structure and development environment
status: Done
assignee: []
created_date: '2025-11-08 03:05'
updated_date: '2025-11-08 03:28'
labels: []
dependencies: []
parent_task_id: task-117
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the initial Elixir project structure for the metadata relay service in a dedicated subfolder. Set up the development environment with Plug/Bandit HTTP server and establish basic endpoint framework.

The service will be a standalone Elixir application using OTP supervision, Plug for routing, and Bandit as the HTTP server. This provides excellent performance, fault tolerance, and consistency with the main Mydia application.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Project folder created at repository root (metadata-relay/)
- [x] #2 Elixir project initialized with mix new metadata_relay --sup
- [x] #3 Dependencies added: bandit, plug, req, cachex, jason
- [x] #4 Basic Plug router with health check endpoint implemented
- [x] #5 Bandit HTTP server configured and starts successfully
- [x] #6 README with local development instructions created

- [x] #7 Server runs locally and responds to HTTP requests on configurable port
<!-- AC:END -->
