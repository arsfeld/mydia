# Installation

Mydia can be installed using Docker (recommended) or from source for development.

## Supported Architectures

Multi-platform images are available for the following architectures:

| Architecture | Available | Tag |
|:------------:|:---------:|-----|
| x86-64 | Yes | amd64-latest |
| arm64 | Yes | arm64-latest |

The multi-arch image `ghcr.io/getmydia/mydia:latest` automatically pulls the correct image for your architecture.

## Database Variants

| Image Tag | Database | Use Case |
|-----------|----------|----------|
| `latest` | SQLite | Default, simpler setup, single-file database |
| `latest-pg` | PostgreSQL | Scalability, existing PostgreSQL infrastructure |

## Docker Compose (Recommended)

See the [Quick Start](quick-start.md) guide for a complete Docker Compose setup.

## Docker CLI

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

## Volume Mappings

| Volume | Function |
|:------:|----------|
| `/config` | Application data, database, and configuration files |
| `/media/movies` | Movies library location |
| `/media/tv` | TV shows library location |
| `/media/downloads` | Download client output directory (optional) |

## Hardlink Support

For optimal storage efficiency, Mydia uses hardlinks when importing media. To enable hardlinks, ensure your downloads and library directories are on the same filesystem:

```yaml
volumes:
  - /path/to/mydia/config:/config
  - /path/to/your/media:/media  # Single mount for downloads AND libraries
```

Organize your host directory structure:

```
/path/to/your/media/
  ├── downloads/          # Download client output
  └── library/
      ├── movies/         # Movies library
      └── tv/             # TV library
```

**Benefits:**

- Instant file operations (no data copying)
- Zero duplicate storage space
- Files remain seeding while available in your library

## User/Group Identifiers

To avoid permission issues, specify the user `PUID` and group `PGID`:

```bash
id your_user
# Example output: uid=1000(your_user) gid=1000(your_user)
```

Use these values for `PUID` and `PGID` in your container configuration.

## Next Steps

- [First Steps](first-steps.md) - Initial configuration guide
- [Environment Variables](../reference/environment-variables.md) - Complete configuration reference
