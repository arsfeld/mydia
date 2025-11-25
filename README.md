# 🎬 Mydia

[![Test & Quality](https://github.com/getmydia/mydia/actions/workflows/test.yml/badge.svg)](https://github.com/getmydia/mydia/actions/workflows/test.yml)

> Your personal media companion, built with Phoenix LiveView

A modern, self-hosted media management platform for tracking, organizing, and monitoring your media library.

## ✨ Features

- 📺 **Unified Media Management** – Track both movies and TV shows with rich metadata from TMDB/TVDB
- 🤖 **Automated Downloads** – Background search and download with quality profiles and smart release ranking
- ⬇️ **Download Clients** – qBittorrent, Transmission, SABnzbd, and NZBGet support
- 🔎 **Indexer Integration** – Search via Prowlarr and Jackett for finding releases
- 👥 **Multi-User System** – Built-in admin/guest roles with request approval workflow
- 🔐 **SSO Support** – Local authentication plus OIDC/OpenID Connect integration
- 🔔 **Release Calendar** – Track upcoming releases and monitor episodes
- 🎨 **Modern Real-Time UI** – Phoenix LiveView with instant updates and responsive design

## 🆚 Comparison with Radarr & Sonarr

| Feature | Mydia | Radarr | Sonarr |
|---------|-------|--------|--------|
| **Media Types** | Movies + TV Shows | Movies only | TV Shows only |
| **Multi-User & Requests** | ✅ Built-in (admin/guest roles) | ❌ Requires Ombi/Overseerr | ❌ Requires Ombi/Overseerr |
| **Authentication** | Local + OIDC/SSO built-in | Local only | Local only |
| **Library Management** | ✅ | ✅ | ✅ |
| **Download Automation** | ✅ | ✅ | ✅ |
| **Quality Profiles** | ✅ | ✅ Advanced | ✅ Advanced |
| **Custom Formats** | ⏳ Planned | ✅ | ✅ |
| **Automatic Upgrades** | ⏳ Planned | ✅ | ✅ |
| **Media Server Integration** | ⏳ Planned | ✅ Plex/Kodi/Jellyfin | ✅ Plex/Kodi/Jellyfin |
| **List Import** | ⏳ Planned | ✅ | ✅ |
| **Native Playback** | 🧪 Experimental | ❌ | ❌ |
| **Technology** | Elixir/Phoenix LiveView | .NET/React | .NET/React |
| **Maturity** | Early development | Production-ready | Production-ready |

**Legend:** ✅ Available | ⏳ Planned | 🧪 Experimental | ❌ Not Available

**Choose Mydia for:** Unified movies+TV management, built-in multi-user support, modern real-time UI, native SSO

**Choose Radarr/Sonarr for:** Mature ecosystem, advanced custom formats, comprehensive automation, wider integrations

## 📊 Quality Profile Features

For users familiar with **Profilarr** and advanced quality management in the Radarr/Sonarr ecosystem, here's how Mydia's quality profile system compares:

**What Mydia Has:**
- ✅ **Built-in Quality Profiles** – 8 predefined profiles covering SD to Remux-2160p, fully customizable via Admin UI
- ✅ **TRaSH Guides Presets** – Browse and import 12 curated profiles based on TRaSH Guides recommendations with one click
- ✅ **Resolution Filtering** – Define allowed qualities per profile (360p through 2160p)
- ✅ **Size Constraints** – Min/max file size limits per profile
- ✅ **Source Preferences** – Prefer BluRay, WEB-DL, REMUX, etc.
- ✅ **Intelligent Scoring** – 0-100 ranking system weighing quality (40%), source (30%), size (20%), and seeder health (10%)
- ✅ **Upgrade Rules** – Enable/disable upgrades and set upgrade-until-quality limits
- ✅ **Per-Item Assignment** – Assign profiles to individual media items or library paths
- ✅ **Automatic Matching** – Profiles actively drive search ranking and download decisions

**What Mydia Doesn't Have (Yet):**
- ❌ **Advanced Custom Formats** – No support for complex multi-condition formats like Profilarr/TRaSH Guides (planned)
- ❌ **Profile Auto-Sync** – No Git-based version control or automatic remote preset updates
- ❌ **Negative Scoring** – Can't penalize unwanted formats, only prefer/allow certain qualities
- ❌ **Tag-Based Filtering** – No PROPER/REPACK preference or CAM/TS blocking (basic detection exists for naming)

**Implementation Difference:**
Mydia's quality profiles are tightly integrated into the core application rather than being a separate configuration management layer. Profiles are stored in the database and used directly by the search and download system to score and rank releases automatically.

## 📸 Screenshots

<table>
  <tr>
    <td><img src="screenshots/homepage.png" alt="Dashboard" /></td>
    <td><img src="screenshots/movies.png" alt="Movies" /></td>
  </tr>
  <tr>
    <td align="center"><b>Dashboard</b></td>
    <td align="center"><b>Movies</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/tv-shows.png" alt="TV Shows" /></td>
    <td><img src="screenshots/calendar.png" alt="Calendar View" /></td>
  </tr>
  <tr>
    <td align="center"><b>TV Shows</b></td>
    <td align="center"><b>Calendar View</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/search.png" alt="Search" /></td>
    <td></td>
  </tr>
  <tr>
    <td align="center"><b>Search</b></td>
    <td></td>
  </tr>
</table>

## 🏗️ Supported Architectures

Multi-platform images are available for the following architectures:

| Architecture | Available | Tag          |
| :----------: | :-------: | ------------ |
|    x86-64    |    ✅     | amd64-latest |
|    arm64     |    ✅     | arm64-latest |

The multi-arch image `ghcr.io/getmydia/mydia:latest` will automatically pull the correct image for your architecture.

## 🚀 Application Setup

1. **Generate required secrets:**

```bash
# Generate SECRET_KEY_BASE
openssl rand -base64 48

# Generate GUARDIAN_SECRET_KEY
openssl rand -base64 48
```

2. Set up your container using Docker Compose (recommended) or Docker CLI
3. Access the web interface at `http://your-server:4000`
4. On first visit, you'll be guided through creating the initial admin user
5. Configure download clients and indexers in the Admin section

## 📦 Usage

Here are some example snippets to help you get started creating a container.

### Docker Compose (Recommended)

```yaml
---
services:
  mydia:
    image: ghcr.io/getmydia/mydia:latest
    container_name: mydia
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - SECRET_KEY_BASE=your-secret-key-base-here # Required: generate with openssl rand -base64 48
      - GUARDIAN_SECRET_KEY=your-guardian-secret-key-here # Required: generate with openssl rand -base64 48
      - PHX_HOST=localhost # Change to your domain
      - PORT=4000
      - MOVIES_PATH=/media/library/movies
      - TV_PATH=/media/library/tv
    volumes:
      - /path/to/mydia/config:/config
      - /path/to/your/media:/media # Single mount enables hardlinks between downloads and libraries
    ports:
      - 4000:4000
    restart: unless-stopped
```

> **Note:** This example uses a single `/media` mount to enable hardlink support. Organize your host directory with subdirectories like `/path/to/your/media/downloads`, `/path/to/your/media/library/movies`, and `/path/to/your/media/library/tv`. Configure your download client to save to `/media/downloads`.

### Docker CLI

```bash
docker run -d \
  --name=mydia \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e SECRET_KEY_BASE=your-secret-key-base-here \
  -e GUARDIAN_SECRET_KEY=your-guardian-secret-key-here \
  -e PHX_HOST=localhost \
  -e PORT=4000 \
  -e MOVIES_PATH=/media/library/movies \
  -e TV_PATH=/media/library/tv \
  -p 4000:4000 \
  -v /path/to/mydia/config:/config \
  -v /path/to/your/media:/media \
  --restart unless-stopped \
  ghcr.io/getmydia/mydia:latest
```

> **Note:** This example uses a single `/media` mount to enable hardlink support. Configure your download client to save to `/media/downloads`.

## 📋 Parameters

Container images are configured using parameters passed at runtime. These parameters are separated by a colon and indicate `external:internal` respectively.

### Ports (`-p`)

|  Parameter  | Function      |
| :---------: | ------------- |
| `4000:4000` | Web interface |

### Environment Variables (`-e`)

|             Env             | Function                                                                                       |
| :-------------------------: | ---------------------------------------------------------------------------------------------- |
|         `PUID=1000`         | User ID for file permissions - see [User / Group Identifiers](#user--group-identifiers) below  |
|         `PGID=1000`         | Group ID for file permissions - see [User / Group Identifiers](#user--group-identifiers) below |
|          `TZ=UTC`           | Timezone (e.g., `America/New_York`)                                                            |
|      `SECRET_KEY_BASE`      | **Required** - Phoenix secret key (generate with: `openssl rand -base64 48`)                   |
|    `GUARDIAN_SECRET_KEY`    | **Required** - JWT signing key (generate with: `openssl rand -base64 48`)                      |
|    `PHX_HOST=localhost`     | Public hostname for the application                                                            |
|         `PORT=4000`         | Web server port                                                                                |
| `MOVIES_PATH=/media/movies` | Movies directory path                                                                          |
|     `TV_PATH=/media/tv`     | TV shows directory path                                                                        |

See the **[Environment Variables Reference](#-environment-variables-reference)** section below for complete configuration options including download clients, indexers, and authentication.

### Volume Mappings (`-v`)

|       Volume       | Function                                            |
| :----------------: | --------------------------------------------------- |
|     `/config`      | Application data, database, and configuration files |
|  `/media/movies`   | Movies library location                             |
|    `/media/tv`     | TV shows library location                           |
| `/media/downloads` | Download client output directory (optional)         |

> **💡 Hardlink Support for Efficient Storage**
>
> For optimal storage efficiency, mydia uses hardlinks by default when importing media. Hardlinks allow the same file to appear in both your download folder and library folder without consuming additional disk space.
>
> **To enable hardlinks**, ensure your downloads and library directories are on the same filesystem by using a single parent volume mount:
>
> ```yaml
> volumes:
>   - /path/to/mydia/config:/config
>   - /path/to/your/media:/media # Single mount for downloads AND libraries
> ```
>
> Then organize your host directory structure like:
>
> ```
> /path/to/your/media/
>   ├── downloads/          # Download client output
>   ├── library/
>   │   ├── movies/         # Movies library
>   │   └── tv/             # TV library
> ```
>
> And configure environment variables:
>
> ```yaml
> environment:
>   - MOVIES_PATH=/media/library/movies
>   - TV_PATH=/media/library/tv
> ```
>
> Configure your download client (qBittorrent, Transmission, etc.) to save files to `/media/downloads`.
>
> **Benefits:**
>
> - Instant file operations (no data copying)
> - Zero duplicate storage space
> - Files remain seeding in your download client while available in your library
>
> **Note:** If your downloads and libraries must be on different filesystems, mydia will automatically fall back to copying files. This works fine but uses more storage space and takes longer.

### Library Path Management

Mydia uses **relative path storage** for media files, which provides several benefits:

- **Flexible Library Relocation**: You can change your library root paths (e.g., from `/mnt/media/Movies` to `/new/storage/Movies`) without breaking existing file references
- **Path Independence**: Media file records are stored relative to their library path, making the database portable
- **Automatic Migration**: When you update library paths via the Admin UI, Mydia validates that existing files are accessible at the new location before making changes
- **Seamless Upgrades**: The migration from absolute to relative paths happens automatically on first startup after upgrade

Library paths can be configured via:

1. Environment variables (`MOVIES_PATH`, `TV_PATH`) - Highest priority
2. Admin UI (Database settings)
3. YAML configuration file (`config/config.yml`)
4. Schema defaults - Lowest priority

Changes to library paths are validated against your existing media files to prevent broken references. If you need to relocate your library, update the environment variables or Admin UI settings, and Mydia will verify file accessibility before applying the changes.

## 👤 User / Group Identifiers

When using volumes (`-v` flags), permissions issues can arise between the host and container. To avoid this, specify the user `PUID` and group `PGID` to ensure files created by the container are owned by your user.

**Finding your IDs:**

```bash
id your_user
```

Example output: `uid=1000(your_user) gid=1000(your_user)`

Use these values for `PUID` and `PGID` in your container configuration.

**Conflict Handling:**

The entrypoint script automatically handles conflicts when the specified PUID/PGID is already in use by another user or group in the container. For example, GID 100 is typically used by the "users" group in Alpine Linux. The container will automatically resolve these conflicts by removing the conflicting user/group and applying your specified IDs.

**Common scenarios:**

- Using `PGID=100` (conflicts with "users" group) - automatically handled ✓
- Using `PUID=99` (conflicts with "nobody" user on some systems) - automatically handled ✓
- Any custom UID/GID that matches your host system - automatically handled ✓

The container logs will show which conflicts were resolved during startup.

## 🔄 Updating the Container

### Via Docker Compose

```bash
docker compose pull
docker compose up -d
```

### Via Docker CLI

```bash
docker stop mydia
docker rm mydia
docker pull ghcr.io/getmydia/mydia:latest
# Run your docker run command again
```

**Note:** Migrations run automatically on startup. Your data in `/config` is preserved across updates.

### Database Backups

Mydia automatically creates database backups before running migrations to ensure your data is safe during updates:

- **Automatic Backups**: When migrations are pending, a timestamped backup is created before running them
- **Backup Location**: Stored alongside the database file (e.g., `/config/mydia_dev_backup_YYYYMMDD_HHMMSS.db`)
- **Automatic Cleanup**: Only the 10 most recent backups are kept to save disk space
- **Manual Restore**: If needed, you can restore from a backup by:
  1. Stop the container
  2. Replace the database file with your chosen backup
  3. Restart the container

To disable automatic backups (not recommended):

```bash
# In docker-compose.yml or docker run command
environment:
  - SKIP_BACKUPS=true
```

For more details about backup and restore procedures, see [docs/deployment/DEPLOYMENT.md](docs/deployment/DEPLOYMENT.md).

### Beta Releases

Beta releases are available for testing new features before they are released to stable. Beta releases:

- Are tagged with `beta` instead of `latest`
- May contain experimental features or breaking changes
- Are not recommended for production use

To use a beta release:

```bash
# Pull the latest beta release
docker pull ghcr.io/getmydia/mydia:beta

# Or use a specific beta version
docker pull ghcr.io/getmydia/mydia:1.2.3-beta.1
```

Update your Docker Compose configuration:

```yaml
services:
  mydia:
    image: ghcr.io/getmydia/mydia:beta # Use beta tag instead of latest
    # ... rest of configuration
```

See [DEPLOYMENT.md](docs/deployment/DEPLOYMENT.md) for advanced deployment topics.

## 📋 Environment Variables Reference

### Required Variables

| Variable              | Description                             | Example                                  |
| --------------------- | --------------------------------------- | ---------------------------------------- |
| `SECRET_KEY_BASE`     | Phoenix secret key for cookies/sessions | Generate with: `openssl rand -base64 48` |
| `GUARDIAN_SECRET_KEY` | JWT signing key for authentication      | Generate with: `openssl rand -base64 48` |

### Container Configuration

| Variable        | Description                                          | Default            |
| --------------- | ---------------------------------------------------- | ------------------ |
| `PUID`          | User ID for file permissions                         | `1000`             |
| `PGID`          | Group ID for file permissions                        | `1000`             |
| `TZ`            | Timezone (e.g., `America/New_York`, `Europe/London`) | `UTC`              |
| `DATABASE_PATH` | Path to SQLite database file                         | `/config/mydia.db` |

### Server Configuration

| Variable           | Description                                                                                                                             | Default                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| `PHX_HOST`         | Public hostname for the application                                                                                                     | `localhost`                       |
| `PORT`             | Web server port                                                                                                                         | `4000`                            |
| `HOST`             | Server binding address                                                                                                                  | `0.0.0.0`                         |
| `URL_SCHEME`       | URL scheme for external links (http/https)                                                                                              | `http`                            |
| `PHX_CHECK_ORIGIN` | WebSocket origin checking. Set to `false` to allow all origins (useful for IP-based access), or comma-separated list of allowed origins | Allows `PHX_HOST` with any scheme |

### Media Library

| Variable                    | Description                 | Default         |
| --------------------------- | --------------------------- | --------------- |
| `MOVIES_PATH`               | Movies directory path       | `/media/movies` |
| `TV_PATH`                   | TV shows directory path     | `/media/tv`     |
| `MEDIA_SCAN_INTERVAL_HOURS` | Hours between library scans | `1`             |

### Authentication

| Variable                      | Description                         | Default                |
| ----------------------------- | ----------------------------------- | ---------------------- |
| `LOCAL_AUTH_ENABLED`          | Enable local username/password auth | `true`                 |
| `OIDC_ENABLED`                | Enable OIDC/OpenID Connect auth     | `false`                |
| `OIDC_DISCOVERY_DOCUMENT_URI` | OIDC discovery endpoint URL         | -                      |
| `OIDC_CLIENT_ID`              | OIDC client ID                      | -                      |
| `OIDC_CLIENT_SECRET`          | OIDC client secret                  | -                      |
| `OIDC_REDIRECT_URI`           | OIDC callback URL                   | Auto-computed          |
| `OIDC_SCOPES`                 | Space-separated scope list          | `openid profile email` |

**OIDC Provider Compatibility:**

Mydia uses standard OAuth2 authentication that works with **minimal provider configuration** - just set client_id, client_secret, and redirect_uris in your provider. No need to configure:

- `token_endpoint_auth_method` settings
- `response_modes` lists
- JWT-based authentication methods
- PAR (Pushed Authorization Request) settings

This should work with any standard OIDC provider including Keycloak, Authelia, Auth0, Okta, Azure AD, and Google.

See [docs/OIDC_TESTING.md](docs/OIDC_TESTING.md) for detailed setup instructions and provider examples.

**User Roles:**

- **Admin**: Full access to all features including media management, downloads, configuration, and request approval
- **Guest**: Can browse media library and submit requests for new content that require admin approval

**OIDC Auto-Promotion**: The first user to log in via OIDC is automatically promoted to admin role. Subsequent OIDC users are assigned the guest role by default.

**First-Time Setup:**

When you first access Mydia, you'll be guided through a setup flow to create the initial admin user. You can either:

- Set a custom password of your choice
- Generate a secure random password that will be displayed once

After the admin user is created, you'll be automatically logged in and can begin configuring your media library.

### Feature Flags

> **⚠️ EXPERIMENTAL FEATURES WARNING**
>
> The features controlled by these flags are **very early in development** and are **unstable or may not work at all**. Do not enable these features unless you understand the risks and are comfortable with potential issues, bugs, or breaking changes. These features are opt-in and disabled by default for good reason.

| Variable           | Description                                                                             | Default |
| ------------------ | --------------------------------------------------------------------------------------- | ------- |
| `ENABLE_PLAYBACK`  | Enable media playback controls and HLS streaming                                        | `false` |
| `ENABLE_CARDIGANN` | Enable native Cardigann indexer support (hundreds of indexers without Prowlarr/Jackett) | `false` |
| `ENABLE_SUBTITLES` | Enable subtitle download and management                                                 | `false` |

### Download Clients

Configure multiple download clients using numbered environment variables (`<N>` = 1, 2, 3, etc.):

| Variable Pattern                         | Description                                                    | Example       |
| ---------------------------------------- | -------------------------------------------------------------- | ------------- |
| `DOWNLOAD_CLIENT_<N>_NAME`               | Client display name                                            | `qBittorrent` |
| `DOWNLOAD_CLIENT_<N>_TYPE`               | Client type (qbittorrent, transmission, sabnzbd, nzbget, http) | `qbittorrent` |
| `DOWNLOAD_CLIENT_<N>_ENABLED`            | Enable this client                                             | `true`        |
| `DOWNLOAD_CLIENT_<N>_PRIORITY`           | Client priority (higher = preferred)                           | `1`           |
| `DOWNLOAD_CLIENT_<N>_HOST`               | Client hostname or IP                                          | `qbittorrent` |
| `DOWNLOAD_CLIENT_<N>_PORT`               | Client port                                                    | `8080`        |
| `DOWNLOAD_CLIENT_<N>_USE_SSL`            | Use SSL/TLS connection                                         | `false`       |
| `DOWNLOAD_CLIENT_<N>_USERNAME`           | Authentication username (Transmission, qBittorrent, NZBGet)    | -             |
| `DOWNLOAD_CLIENT_<N>_PASSWORD`           | Authentication password (Transmission, qBittorrent, NZBGet)    | -             |
| `DOWNLOAD_CLIENT_<N>_API_KEY`            | API key (SABnzbd)                                              | -             |
| `DOWNLOAD_CLIENT_<N>_CATEGORY`           | Default download category                                      | -             |
| `DOWNLOAD_CLIENT_<N>_DOWNLOAD_DIRECTORY` | Download output directory                                      | -             |

**Supported Download Clients:**

- **Torrent Clients**: qBittorrent, Transmission
- **Usenet Clients**: SABnzbd, NZBGet

Example configurations:

```bash
# qBittorrent
DOWNLOAD_CLIENT_1_NAME=qBittorrent
DOWNLOAD_CLIENT_1_TYPE=qbittorrent
DOWNLOAD_CLIENT_1_HOST=qbittorrent
DOWNLOAD_CLIENT_1_PORT=8080
DOWNLOAD_CLIENT_1_USERNAME=admin
DOWNLOAD_CLIENT_1_PASSWORD=adminpass

# Transmission
DOWNLOAD_CLIENT_2_NAME=Transmission
DOWNLOAD_CLIENT_2_TYPE=transmission
DOWNLOAD_CLIENT_2_HOST=transmission
DOWNLOAD_CLIENT_2_PORT=9091
DOWNLOAD_CLIENT_2_USERNAME=admin
DOWNLOAD_CLIENT_2_PASSWORD=adminpass

# SABnzbd (Usenet)
DOWNLOAD_CLIENT_3_NAME=SABnzbd
DOWNLOAD_CLIENT_3_TYPE=sabnzbd
DOWNLOAD_CLIENT_3_HOST=sabnzbd
DOWNLOAD_CLIENT_3_PORT=8080
DOWNLOAD_CLIENT_3_API_KEY=your-sabnzbd-api-key

# NZBGet (Usenet)
DOWNLOAD_CLIENT_4_NAME=NZBGet
DOWNLOAD_CLIENT_4_TYPE=nzbget
DOWNLOAD_CLIENT_4_HOST=nzbget
DOWNLOAD_CLIENT_4_PORT=6789
DOWNLOAD_CLIENT_4_USERNAME=nzbget
DOWNLOAD_CLIENT_4_PASSWORD=tegbzn6789
```

### Indexers

Configure multiple indexers using numbered environment variables (`<N>` = 1, 2, 3, etc.):

| Variable Pattern          | Description                              | Example                |
| ------------------------- | ---------------------------------------- | ---------------------- |
| `INDEXER_<N>_NAME`        | Indexer display name                     | `Prowlarr`             |
| `INDEXER_<N>_TYPE`        | Indexer type (prowlarr, jackett, public) | `prowlarr`             |
| `INDEXER_<N>_ENABLED`     | Enable this indexer                      | `true`                 |
| `INDEXER_<N>_PRIORITY`    | Indexer priority (higher = preferred)    | `1`                    |
| `INDEXER_<N>_BASE_URL`    | Indexer base URL                         | `http://prowlarr:9696` |
| `INDEXER_<N>_API_KEY`     | Indexer API key                          | -                      |
| `INDEXER_<N>_INDEXER_IDS` | Comma-separated indexer IDs              | `1,2,3`                |
| `INDEXER_<N>_CATEGORIES`  | Comma-separated categories               | `movies,tv`            |
| `INDEXER_<N>_RATE_LIMIT`  | API rate limit (requests/sec)            | -                      |

Example for Prowlarr:

```bash
INDEXER_1_NAME=Prowlarr
INDEXER_1_TYPE=prowlarr
INDEXER_1_BASE_URL=http://prowlarr:9696
INDEXER_1_API_KEY=your-prowlarr-api-key-here
```

Example for Jackett:

```bash
INDEXER_2_NAME=Jackett
INDEXER_2_TYPE=jackett
INDEXER_2_BASE_URL=http://jackett:9117
INDEXER_2_API_KEY=your-jackett-api-key-here
```

### Advanced Configuration

| Variable    | Description                                         | Default |
| ----------- | --------------------------------------------------- | ------- |
| `LOG_LEVEL` | Application log level (debug, info, warning, error) | `info`  |

### Configuration Precedence

Configuration is loaded in this order (highest to lowest priority):

1. **Environment Variables** - Override everything
2. **Database Settings** - Configured via Admin UI
3. **YAML File** - From `config/config.yml`
4. **Schema Defaults** - Built-in defaults

## 🔧 Development

### Local Setup

**With Docker (Recommended):**

```bash
# Start everything
./dev up -d

# Run migrations
./dev mix ecto.migrate

# View at http://localhost:4000
# Check logs for the auto-generated admin password:
./dev logs | grep "DEFAULT ADMIN USER CREATED" -A 10
```

See all commands with `./dev`

**Without Docker:**

```bash
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000)

### Continuous Integration

All pull requests and commits to the main branch automatically run:

- ✓ Code compilation with warnings as errors
- ✓ Code formatting checks
- ✓ Static analysis with Credo
- ✓ Full test suite (ExUnit + LiveView tests)
- ✓ End-to-end tests (Playwright)
- ✓ Docker build verification

Run these checks locally before committing:

```bash
mix precommit
```

### End-to-End Testing

Mydia uses Playwright for comprehensive browser-based testing of complete user workflows, JavaScript interactions, and real-time features.

**Quick Start:**

```bash
# Install dependencies
cd assets
npm install

# Run E2E tests (Chromium only, fast)
npm run test:e2e

# Run with UI for debugging
npm run test:e2e:ui

# Run in headed mode (see browser)
npm run test:e2e -- --headed
```

**What's Tested:**

- ✓ Authentication flows (local + OIDC)
- ✓ LiveView real-time updates
- ✓ JavaScript/Alpine.js interactions
- ✓ Complete user workflows
- ✓ Cross-browser compatibility

**CI Integration:**

E2E tests run automatically in GitHub Actions on every PR and push. Tests use a Docker Compose environment with mock services (OAuth2, Prowlarr, qBittorrent) for fast, reliable testing.

**Writing Tests:**

```typescript
import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "../helpers/auth";
import { assertFlashMessage } from "../helpers/liveview";

test("admin can update settings", async ({ page }) => {
  await loginAsAdmin(page);
  await page.goto("/admin/settings");
  await page.fill('input[name="setting"]', "value");
  await page.click('button[type="submit"]');
  await assertFlashMessage(page, "success", "Settings saved");
});
```

**Full Documentation:** See [docs/testing/e2e.md](docs/testing/e2e.md) for complete guide on running, writing, and debugging E2E tests.

### Git Hooks

Automatic pre-commit hooks are available to catch formatting issues before they reach CI:

```bash
# Install hooks (one-time setup)
./scripts/install-git-hooks.sh
```

The pre-commit hook will automatically run `mix format --check-formatted` before each commit. If formatting issues are found, the commit will be blocked with instructions to fix them.

To bypass the hook in exceptional cases (not recommended):

```bash
git commit --no-verify
```

### Customization

Create `compose.override.yml` to add services like Transmission, Prowlarr, Jackett, or custom configurations:

```bash
cp compose.override.yml.example compose.override.yml
# Edit and uncomment services you need
./dev up -d
```

### Screenshots

Capture automated screenshots for documentation:

```bash
./take-screenshots
```

See `assets/SCREENSHOTS.md` for configuration options.

## 🛠️ Tech Stack

- Phoenix 1.8 + LiveView
- Ecto + SQLite
- Oban (background jobs)
- Tailwind CSS + DaisyUI
- Req (HTTP client)

## 📝 TRaSH Guides Naming Compliance

Mydia implements [TRaSH Guides](https://trash-guides.info/)-compatible filename naming to preserve quality metadata and prevent download loops. Core features like title, year, quality (source/resolution), PROPER/REPACK flags, codec, and release group are fully implemented. Partial support exists for HDR detection (basic detection without format distinction) and audio codecs (codec without channel info). Missing features include edition tags, custom formats, 3D indicators, audio channels, specific HDR formats, and episode title truncation.

| Feature | Movies | TV Shows | Notes |
|---------|--------|----------|-------|
| **Implemented** | Title, Year, Quality, Codec, Release Group, PROPER/REPACK | Title, Year, S##E##, Episode Title, Quality, Codec, Release Group, PROPER/REPACK | Prevents duplicate downloads |
| **Partial** | HDR (basic), Audio codec | HDR (basic), Audio codec | No format distinction or channel info |
| **Missing** | Edition tags, Custom formats, 3D, Audio channels | Custom formats, Audio channels, Title truncation | Planned enhancements |

**Example output:** `The Matrix (1999) [BluRay-1080p][DTS][x264]-GROUP.mkv` • `Breaking Bad (2008) - S01E01 - Pilot [BluRay-1080p][x264]-GROUP.mkv`

---

Built with Elixir & Phoenix
