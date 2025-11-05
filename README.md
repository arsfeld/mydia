# 🎬 Mydia

> Your personal media companion, built with Phoenix LiveView

A modern, self-hosted media management platform for tracking, organizing, and monitoring your media library.

## ✨ Features

- 📺 **Smart Library Management** – Track TV shows, movies, and episodes with rich metadata
- 🔔 **Release Monitoring** – Never miss new episodes with calendar views and notifications
- 🔍 **Metadata Enrichment** – Automatic metadata fetching and matching
- ⬇️ **Download Integration** – Seamless torrent client connectivity (Transmission, qBittorrent)
- 🎯 **Episode Tracking** – Monitor individual episodes or entire seasons
- 🎨 **Modern UI** – Built with LiveView, Tailwind CSS, and DaisyUI

## 🚀 Quick Start

### Docker (Recommended)

```bash
# Start everything
./dev up -d

# Run migrations
./dev mix ecto.migrate

# View at http://localhost:4000
# Login: admin / admin
```

See all commands with `./dev`

### Local Development

```bash
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000)

## 📦 Production Deployment

Pre-built Docker images are available for multiple platforms (amd64, arm64):

```bash
# Pull the latest image
docker pull ghcr.io/arsfeld/mydia:latest

# Or pull a specific version
docker pull ghcr.io/arsfeld/mydia:v1.0.0

# Run with docker-compose
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete production deployment instructions including environment configuration, volume setup, and upgrade procedures.

## 🔧 Development

### Customization

Create `compose.override.yml` to add services like Transmission, Prowlarr, or custom configurations:

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

---

Built with Elixir & Phoenix
