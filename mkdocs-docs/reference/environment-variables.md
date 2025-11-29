# Environment Variables Reference

Complete reference of all environment variables supported by Mydia.

## Complete Example

A production-ready Docker Compose setup with Mydia, Transmission, and Prowlarr fully configured:

```yaml
services:
  # =============================================================================
  # MYDIA - Media Management
  # =============================================================================
  mydia:
    image: ghcr.io/getmydia/mydia:latest
    container_name: mydia
    environment:
      # --- Required Secrets (generate with: openssl rand -base64 48) ---
      - SECRET_KEY_BASE=your-64-character-secret-key-base-here
      - GUARDIAN_SECRET_KEY=your-64-character-guardian-secret-here

      # --- Container Settings ---
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York

      # --- Server Settings ---
      - PHX_HOST=mydia.local          # Your hostname or IP
      - PORT=4000
      - URL_SCHEME=http               # Use 'https' if behind SSL proxy

      # --- Media Library Paths ---
      - MOVIES_PATH=/media/library/movies
      - TV_PATH=/media/library/tv

      # --- Transmission Download Client ---
      - DOWNLOAD_CLIENT_1_NAME=Transmission
      - DOWNLOAD_CLIENT_1_TYPE=transmission
      - DOWNLOAD_CLIENT_1_ENABLED=true
      - DOWNLOAD_CLIENT_1_HOST=transmission
      - DOWNLOAD_CLIENT_1_PORT=9091
      - DOWNLOAD_CLIENT_1_USERNAME=admin
      - DOWNLOAD_CLIENT_1_PASSWORD=transmission
      - DOWNLOAD_CLIENT_1_CATEGORY=mydia
      - DOWNLOAD_CLIENT_1_DOWNLOAD_DIRECTORY=/media/downloads

      # --- Prowlarr Indexer ---
      - INDEXER_1_NAME=Prowlarr
      - INDEXER_1_TYPE=prowlarr
      - INDEXER_1_ENABLED=true
      - INDEXER_1_BASE_URL=http://prowlarr:9696
      - INDEXER_1_API_KEY=your-prowlarr-api-key-here
    volumes:
      - ./config/mydia:/config
      - /path/to/media:/media        # Single mount for hardlink support
    ports:
      - "4000:4000"
    depends_on:
      - transmission
      - prowlarr
    restart: unless-stopped

  # =============================================================================
  # TRANSMISSION - Torrent Client
  # =============================================================================
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - USER=admin
      - PASS=transmission
    volumes:
      - ./config/transmission:/config
      - /path/to/media/downloads:/media/downloads
    ports:
      - "9091:9091"                   # Web UI
      - "51413:51413"                 # Torrent port
      - "51413:51413/udp"
    restart: unless-stopped

  # =============================================================================
  # PROWLARR - Indexer Manager
  # =============================================================================
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./config/prowlarr:/config
    ports:
      - "9696:9696"
    restart: unless-stopped
```

!!! tip "Directory Structure"
    For hardlink support, organize your media directory like this:
    ```
    /path/to/media/
    ├── downloads/           # Transmission saves here
    └── library/
        ├── movies/          # MOVIES_PATH
        └── tv/              # TV_PATH
    ```

!!! note "Getting Your Prowlarr API Key"
    1. Start Prowlarr and access `http://localhost:9696`
    2. Go to **Settings → General**
    3. Copy the **API Key** and paste it into `INDEXER_1_API_KEY`

---

## Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Phoenix secret key for cookies/sessions | Generate with: `openssl rand -base64 48` |
| `GUARDIAN_SECRET_KEY` | JWT signing key for authentication | Generate with: `openssl rand -base64 48` |

## Container Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone (e.g., `America/New_York`) | `UTC` |
| `DATABASE_PATH` | Path to SQLite database file | `/config/mydia.db` |

## Server Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PHX_HOST` | Public hostname for the application | `localhost` |
| `PORT` | Web server port | `4000` |
| `HOST` | Server binding address | `0.0.0.0` |
| `URL_SCHEME` | URL scheme for external links | `http` |
| `PHX_CHECK_ORIGIN` | WebSocket origin checking | Allows `PHX_HOST` with any scheme |

### PHX_CHECK_ORIGIN Options

- `false` - Allow all origins (useful for IP-based access)
- Comma-separated list of allowed origins

## Media Library

| Variable | Description | Default |
|----------|-------------|---------|
| `MOVIES_PATH` | Movies directory path | `/media/movies` |
| `TV_PATH` | TV shows directory path | `/media/tv` |
| `MEDIA_SCAN_INTERVAL_HOURS` | Hours between library scans | `1` |

### Additional Library Paths

Configure additional libraries using numbered variables (`<N>` = 1, 2, 3, etc.):

| Variable Pattern | Description | Example |
|------------------|-------------|---------|
| `LIBRARY_PATH_<N>_PATH` | Directory path | `/media/music` |
| `LIBRARY_PATH_<N>_TYPE` | Library type | `music` |
| `LIBRARY_PATH_<N>_MONITORED` | Enable monitoring | `true` |
| `LIBRARY_PATH_<N>_SCAN_INTERVAL` | Scan interval in seconds | `3600` |
| `LIBRARY_PATH_<N>_QUALITY_PROFILE_ID` | Quality profile ID | `1` |

**Library Types:** `movies`, `series`, `mixed`, `music`, `books`, `adult`

## Authentication

| Variable | Description | Default |
|----------|-------------|---------|
| `LOCAL_AUTH_ENABLED` | Enable local username/password auth | `true` |
| `OIDC_ENABLED` | Enable OIDC/OpenID Connect auth | `false` |
| `OIDC_DISCOVERY_DOCUMENT_URI` | OIDC discovery endpoint URL | - |
| `OIDC_CLIENT_ID` | OIDC client ID | - |
| `OIDC_CLIENT_SECRET` | OIDC client secret | - |
| `OIDC_REDIRECT_URI` | OIDC callback URL | Auto-computed |
| `OIDC_SCOPES` | Space-separated scope list | `openid profile email` |

## Feature Flags

!!! warning "Experimental Features"
    These features are unstable and may not work correctly. Enable at your own risk.

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_PLAYBACK` | Enable media playback controls and HLS streaming | `false` |
| `ENABLE_CARDIGANN` | Enable native Cardigann indexer support | `true` |
| `ENABLE_SUBTITLES` | Enable subtitle download and management | `false` |

## Download Clients

Configure multiple clients using numbered variables (`<N>` = 1, 2, 3, etc.):

| Variable Pattern | Description | Example |
|------------------|-------------|---------|
| `DOWNLOAD_CLIENT_<N>_NAME` | Display name | `qBittorrent` |
| `DOWNLOAD_CLIENT_<N>_TYPE` | Client type | `qbittorrent` |
| `DOWNLOAD_CLIENT_<N>_ENABLED` | Enable this client | `true` |
| `DOWNLOAD_CLIENT_<N>_PRIORITY` | Client priority (higher = preferred) | `1` |
| `DOWNLOAD_CLIENT_<N>_HOST` | Hostname or IP | `qbittorrent` |
| `DOWNLOAD_CLIENT_<N>_PORT` | Client port | `8080` |
| `DOWNLOAD_CLIENT_<N>_USE_SSL` | Use SSL/TLS | `false` |
| `DOWNLOAD_CLIENT_<N>_USERNAME` | Auth username | - |
| `DOWNLOAD_CLIENT_<N>_PASSWORD` | Auth password | - |
| `DOWNLOAD_CLIENT_<N>_API_KEY` | API key (SABnzbd) | - |
| `DOWNLOAD_CLIENT_<N>_CATEGORY` | Default category | - |
| `DOWNLOAD_CLIENT_<N>_DOWNLOAD_DIRECTORY` | Download directory | - |

**Client Types:** `qbittorrent`, `transmission`, `sabnzbd`, `nzbget`

## Indexers

Configure multiple indexers using numbered variables (`<N>` = 1, 2, 3, etc.):

| Variable Pattern | Description | Example |
|------------------|-------------|---------|
| `INDEXER_<N>_NAME` | Display name | `Prowlarr` |
| `INDEXER_<N>_TYPE` | Indexer type | `prowlarr` |
| `INDEXER_<N>_ENABLED` | Enable this indexer | `true` |
| `INDEXER_<N>_PRIORITY` | Search priority (higher = preferred) | `1` |
| `INDEXER_<N>_BASE_URL` | Indexer base URL | `http://prowlarr:9696` |
| `INDEXER_<N>_API_KEY` | Indexer API key | - |
| `INDEXER_<N>_INDEXER_IDS` | Comma-separated indexer IDs | `1,2,3` |
| `INDEXER_<N>_CATEGORIES` | Comma-separated categories | `movies,tv` |
| `INDEXER_<N>_RATE_LIMIT` | Rate limit (requests/sec) | - |

**Indexer Types:** `prowlarr`, `jackett`, `public`

## PostgreSQL Configuration

For PostgreSQL deployments (using `latest-pg` image):

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_TYPE` | Set to `postgres` | `sqlite` |
| `DATABASE_HOST` | PostgreSQL hostname | `localhost` |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `DATABASE_NAME` | Database name | `mydia` |
| `DATABASE_USER` | Database username | `postgres` |
| `DATABASE_PASSWORD` | Database password | - |
| `POOL_SIZE` | Connection pool size | `10` |

## Advanced Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | Log level (debug, info, warning, error) | `info` |
| `SKIP_BACKUPS` | Disable automatic database backups | `false` |

## Configuration Precedence

Configuration is loaded in this order (highest to lowest priority):

1. **Environment Variables** - Override everything
2. **Database Settings** - Configured via Admin UI
3. **YAML File** - From `config/config.yml`
4. **Schema Defaults** - Built-in defaults
