# Production Deployment Guide

This guide covers deploying Mydia using Docker in a production environment.

## Installation Options

### Option 1: Pre-built Images (Recommended)

Pull the latest pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/arsfeld/mydia:latest
```

Or pull a specific version:

```bash
docker pull ghcr.io/arsfeld/mydia:v1.0.0
```

### Option 2: Build from Source

Build the image locally from the repository:

```bash
docker build -t mydia:latest -f Dockerfile .
```

## Quick Start

### 1. Generate Secrets

Generate required secrets for production:

```bash
# Generate SECRET_KEY_BASE
openssl rand -base64 48

# Generate GUARDIAN_SECRET_KEY
openssl rand -base64 48
```

### 2. Configure Environment

Copy the example environment file and update it with your values:

```bash
cp .env.prod.example .env.prod
```

Edit `.env.prod` and set:
- `SECRET_KEY_BASE` - Use the first generated secret
- `GUARDIAN_SECRET_KEY` - Use the second generated secret
- `PHX_HOST` - Your domain name
- `MEDIA_PATH_*` - Paths to your media directories
- (Optional) OIDC settings for authentication

### 3. Pull the Image

```bash
docker pull ghcr.io/arsfeld/mydia:latest
```

Or skip this step - docker-compose will pull the image automatically.

### 4. Update docker-compose.prod.yml

Ensure your `docker-compose.prod.yml` references the published image:

```yaml
services:
  mydia:
    image: ghcr.io/arsfeld/mydia:latest  # Or specify a version like :v1.0.0
    # ... rest of configuration
```

### 5. Run with Docker Compose

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## Manual Docker Run

If you prefer to run without Docker Compose:

```bash
docker run -d \
  --name mydia \
  -p 4000:4000 \
  --env-file .env.prod \
  -v mydia_data:/data \
  -v /path/to/movies:/media/movies \
  -v /path/to/tv:/media/tv \
  -v /path/to/downloads:/media/downloads \
  ghcr.io/arsfeld/mydia:latest
```

## Health Check

The application includes a health check endpoint at `/health` that returns JSON:

```bash
curl http://localhost:4000/health
```

Response:
```json
{
  "status": "ok",
  "service": "mydia",
  "timestamp": "2025-11-05T00:00:00Z"
}
```

## Configuration

### Required Environment Variables

- `SECRET_KEY_BASE` - Phoenix secret key (generate with `openssl rand -base64 48`)
- `GUARDIAN_SECRET_KEY` - JWT secret key (generate with `openssl rand -base64 48`)
- `DATABASE_PATH` - Path to SQLite database file (default: `/data/mydia.db`)

### Optional Environment Variables

- `PHX_HOST` - Hostname for the application (default: `localhost`)
- `PORT` - HTTP port (default: `4000`)
- `POOL_SIZE` - Database connection pool size (default: `5`)
- `MEDIA_PATH_MOVIES` - Path to movie library
- `MEDIA_PATH_TV` - Path to TV show library
- `MEDIA_PATH_DOWNLOADS` - Path to downloads directory

### OIDC Authentication (Optional)

If you want to use OpenID Connect authentication:

- `OIDC_DISCOVERY_DOCUMENT_URI` - OIDC discovery endpoint
- `OIDC_CLIENT_ID` - OAuth client ID
- `OIDC_CLIENT_SECRET` - OAuth client secret
- `OIDC_REDIRECT_URI` - OAuth redirect URI
- `OIDC_SCOPES` - OAuth scopes (default: `openid profile email`)

## Volumes

The production setup uses the following volumes:

- `mydia_data` - Application data and SQLite database
- Media directories - Mount your existing media library directories

## Ports

- `4000` - HTTP port for the web interface

## First Run

On first startup, the application will:
1. Run database migrations
2. Create default quality profiles
3. Start the web server on port 4000

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker logs mydia
```

### Health check failing

Ensure the application is listening on the correct port:
```bash
docker exec mydia curl -f http://localhost:4000/health
```

### Database permission issues

Ensure the data volume has correct permissions:
```bash
docker exec mydia ls -la /data
```

## Upgrading

To upgrade to a new version:

1. Pull the new image
2. Stop the current container
3. Start a new container with the new image

Migrations will run automatically on startup.

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod down
docker pull ghcr.io/arsfeld/mydia:latest
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

To upgrade to a specific version, specify the version tag:

```bash
docker pull ghcr.io/arsfeld/mydia:v1.0.0
# Update docker-compose.prod.yml to use the specific version
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## Release Process

Mydia uses automated CI/CD to build and publish Docker images.

### For Maintainers: Creating a Release

To create a new release:

1. Update version numbers if needed (in mix.exs, etc.)
2. Commit all changes
3. Create and push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

4. GitHub Actions will automatically:
   - Build multi-platform Docker images (amd64, arm64)
   - Tag the image with the version number and 'latest'
   - Publish to GitHub Container Registry
   - Generate build attestation for supply chain security

5. Monitor the workflow at: https://github.com/arsfeld/mydia/actions

### Available Image Tags

Images are published to `ghcr.io/arsfeld/mydia` with the following tags:

- `latest` - Most recent stable release
- `v1.0.0` - Specific version (full semver)
- `v1.0` - Minor version (receives patch updates)
- `v1` - Major version (receives minor and patch updates)

### Image Platforms

All images support multiple platforms:
- `linux/amd64` - Standard x86_64 systems
- `linux/arm64` - ARM64 systems (e.g., Apple Silicon, Raspberry Pi 4+)
