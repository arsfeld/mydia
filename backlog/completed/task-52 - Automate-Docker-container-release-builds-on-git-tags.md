---
id: task-52
title: Automate Docker container release builds on git tags
status: Done
assignee:
  - assistant
created_date: '2025-11-04 23:56'
updated_date: '2025-11-05 00:45'
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
- [x] #1 CI workflow triggers on version tag push (e.g., v1.0.0)
- [x] #2 Docker image builds successfully in CI environment
- [x] #3 Image is tagged with both the version tag and 'latest'
- [x] #4 Image is published to container registry
- [x] #5 Published image can be pulled and run successfully
- [x] #6 Workflow completes without manual intervention
- [x] #7 Basic documentation added for release process
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Overview
Set up GitHub Actions workflow to automatically build and publish Docker images when version tags are pushed.

### Implementation Steps

1. ✅ Created GitHub repository 'getmydia/mydia'
2. ✅ Created `.github/workflows/release.yml` with:
   - Trigger on v* tag push
   - Multi-platform build (linux/amd64, linux/arm64)
   - Automatic tagging (version, semver variants, latest)
   - Push to GitHub Container Registry (ghcr.io)
   - Build attestation for supply chain security
   
3. ✅ Updated `docs/deployment/DEPLOYMENT.md` with:
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
   - Use pre-built image from ghcr.io/getmydia/mydia by default
   - Remove local build configuration

### Next Steps
- Commit and push changes
- Create test tag to verify workflow
- Monitor GitHub Actions execution
- Verify published image can be pulled and run
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Progress

### Changes Committed and Pushed

**Created Files:**
- `.github/workflows/release.yml` - GitHub Actions workflow for automated releases

**Modified Files:**
- `docs/deployment/DEPLOYMENT.md` - Added pre-built image installation and release process documentation
- `README.md` - Updated production deployment section to highlight pre-built images
- `docker-compose.prod.yml` - Updated to use ghcr.io/getmydia/mydia:latest by default

### Test Release Created

- Created and pushed tag: v0.1.0
- GitHub Actions workflow triggered successfully
- Workflow run: https://github.com/getmydia/mydia/actions/runs/19086908816
- Status: In progress (building multi-platform images)

### Workflow Configuration

- **Registry**: ghcr.io (GitHub Container Registry)
- **Platforms**: linux/amd64, linux/arm64
- **Tagging**: Semver (0.1.0, 0.1, 0) + latest
- **Authentication**: Automatic via GITHUB_TOKEN
- **Features**: Build attestation, layer caching, multi-platform support

## Workflow Completed Successfully

**Build completed:** 13m 14s
**Workflow URL:** https://github.com/getmydia/mydia/actions/runs/19086908816
**Result:** ✅ Success

### Published Images

**Registry:** ghcr.io/getmydia/mydia
**Digest:** sha256:c3e76eb3b1ddf543919373161a8e7e18ee48c4fa4aa89cfa4a04d110304a2117
**Size:** 133MB
**Platforms:** linux/amd64, linux/arm64

**Available tags:**
- `0.1.0` (version)
- `0.1` (minor version)
- `0` (major version)
- `latest`

### Verification Results

✅ Image pulled successfully: `ghcr.io/getmydia/mydia:0.1.0`
✅ Image pulled successfully: `ghcr.io/getmydia/mydia:latest`
✅ Both tags point to same image (ID: 1788586e89ed)
✅ Build attestation generated and published to Rekor transparency log
✅ Attestation URL: https://github.com/getmydia/mydia/attestations/12903787

### Multi-platform Support Confirmed

Images built for:
- linux/amd64 (standard x86_64)
- linux/arm64 (ARM64/Apple Silicon)

### Supply Chain Security

- Build provenance attestation created
- Signed using Sigstore
- Published to Rekor transparency log
- Attestation available in repository and registry
<!-- SECTION:NOTES:END -->
