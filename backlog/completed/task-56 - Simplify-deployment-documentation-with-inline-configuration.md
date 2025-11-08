---
id: task-56
title: Simplify deployment documentation with inline configuration
status: Done
assignee: []
created_date: '2025-11-05 02:34'
updated_date: '2025-11-05 02:44'
labels:
  - documentation
  - deployment
  - user-experience
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Streamline the deployment process by embedding all necessary configuration directly in README.md. Remove the need for users to download separate docker-compose.prod.yml and .env files. Provide clear, copy-pasteable examples for both `docker run` and `docker compose` that users can customize directly from the README. Include a comprehensive reference list of all supported environment variables and configuration options that both deployment methods reference.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 README.md contains inline docker-compose.yml configuration for production deployment
- [x] #2 README.md contains docker run command example with all necessary flags and volumes
- [x] #3 Comprehensive environment variable reference section added to README.md listing all supported options
- [x] #4 Both docker run and docker compose examples reference the environment variable section
- [x] #5 docker-compose.prod.yml file is removed from repository
- [x] #6 .env.prod.example file handling is clarified or removed if no longer needed
- [x] #7 Users can copy configuration directly from README without downloading additional files
- [x] #8 Configuration examples include sensible defaults and clear comments
- [x] #9 Volume mounts and port mappings are clearly documented in both formats
- [x] #10 Migration from old deployment method is documented if needed
<!-- AC:END -->
