---
id: task-52
title: Automate Docker container release builds on git tags
status: In Progress
assignee:
  - assistant
created_date: '2025-11-04 23:56'
updated_date: '2025-11-05 00:13'
labels:
  - docker
  - ci-cd
  - deployment
  - automation
dependencies:
  - task-10
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up automated CI/CD pipeline to build and publish Docker images when version tags are pushed. This enables simple, repeatable releases without manual build steps. Users can pull versioned images directly from the registry.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CI workflow triggers on version tag push (e.g., v1.0.0)
- [ ] #2 Docker image builds successfully in CI environment
- [ ] #3 Image is tagged with both the version tag and 'latest'
- [ ] #4 Image is published to container registry
- [ ] #5 Published image can be pulled and run successfully
- [ ] #6 Workflow completes without manual intervention
- [ ] #7 Basic documentation added for release process
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Overview
Set up GitHub Actions workflow to automatically build and publish Docker images when version tags are pushed.

### Implementation Steps

1. ✅ Created GitHub repository 'arsfeld/mydia'
2. ✅ Created `.github/workflows/release.yml` with:
   - Trigger on v* tag push
   - Multi-platform build (linux/amd64, linux/arm64)
   - Automatic tagging (version, semver variants, latest)
   - Push to GitHub Container Registry (ghcr.io)
   - Build attestation for supply chain security
   
3. ✅ Updated `DEPLOYMENT.md` with:
   - Installation options (pre-built vs build from source)
   - Updated Quick Start to use pre-built images
   - Added Release Process section documenting:
     - How to create releases
     - Available image tags
     - Supported platforms
     
4. ✅ Updated `README.md` to:
   - Show pre-built image installation as primary option
   - Document version-specific pulls
   
5. ✅ Updated `docker-compose.prod.yml` to:
   - Use pre-built image from ghcr.io by default
   - Remove local build configuration

### Next Steps
- Commit and push changes
- Create test tag to verify workflow
- Monitor GitHub Actions execution
- Verify published image can be pulled and run
<!-- SECTION:PLAN:END -->
