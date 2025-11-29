# Mydia

[![Test & Quality](https://github.com/getmydia/mydia/actions/workflows/test.yml/badge.svg)](https://github.com/getmydia/mydia/actions/workflows/test.yml)
[![Documentation](https://github.com/getmydia/mydia/actions/workflows/docs.yml/badge.svg)](https://getmydia.github.io/mydia)

**Your personal media companion, built with Phoenix LiveView**

A modern, self-hosted media management platform for tracking, organizing, and monitoring your movies and TV shows.

> **Warning:** Mydia is in early development (0.x.x). Expect breaking changes. [Report issues](https://github.com/getmydia/mydia/issues) or [request features](https://github.com/getmydia/mydia/issues/new).

## Quick Start

**1. Generate secrets:**

```bash
openssl rand -base64 48  # SECRET_KEY_BASE
openssl rand -base64 48  # GUARDIAN_SECRET_KEY
```

**2. Create `docker-compose.yml`:**

```yaml
services:
  mydia:
    image: ghcr.io/getmydia/mydia:latest
    container_name: mydia
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - SECRET_KEY_BASE=your-secret-key-base-here
      - GUARDIAN_SECRET_KEY=your-guardian-secret-key-here
      - PHX_HOST=localhost
      - MOVIES_PATH=/media/library/movies
      - TV_PATH=/media/library/tv
    volumes:
      - ./config:/config
      - /path/to/media:/media
    ports:
      - 4000:4000
    restart: unless-stopped
```

**3. Start and access:**

```bash
docker compose up -d
```

Open http://localhost:4000 and create your admin account.

## Features

- **Unified Media Management** - Movies + TV shows with TMDB/TVDB metadata
- **Automated Downloads** - Quality profiles, smart release ranking
- **Download Clients** - qBittorrent, Transmission, SABnzbd, NZBGet
- **Indexers** - Prowlarr, Jackett, built-in Cardigann (experimental)
- **Multi-User** - Admin/guest roles with request workflow
- **SSO** - Local auth + OIDC/OpenID Connect
- **Real-Time UI** - Phoenix LiveView with instant updates

## Documentation

Full documentation available at **[getmydia.github.io/mydia](https://getmydia.github.io/mydia)**

- [Installation Guide](https://getmydia.github.io/mydia/getting-started/installation/)
- [Configuration Reference](https://getmydia.github.io/mydia/reference/environment-variables/)
- [Download Clients Setup](https://getmydia.github.io/mydia/user-guide/download-clients/)
- [SSO/OIDC Setup](https://getmydia.github.io/mydia/advanced/oidc/)
- [PostgreSQL Support](https://getmydia.github.io/mydia/advanced/postgresql/)
- [Development Guide](https://getmydia.github.io/mydia/development/setup/)

## Screenshots

| Dashboard | Movies |
|:---------:|:------:|
| ![Dashboard](screenshots/homepage.png) | ![Movies](screenshots/movies.png) |

| TV Shows | Calendar |
|:--------:|:--------:|
| ![TV Shows](screenshots/tv-shows.png) | ![Calendar](screenshots/calendar.png) |

## Contributing

```bash
./dev up -d              # Start development environment
./dev mix ecto.migrate   # Run migrations
./dev mix test           # Run tests
./dev mix precommit      # Run all checks
```

See the [Development Guide](https://getmydia.github.io/mydia/development/setup/) for details.

### Documentation

Docs are built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). Requires [uv](https://docs.astral.sh/uv/).

```bash
uv sync --project mkdocs-docs            # Install dependencies
uv run --project mkdocs-docs mkdocs serve   # Serve at http://localhost:8000
uv run --project mkdocs-docs mkdocs build   # Build static site to /site
```

## License

Built with Elixir & Phoenix
