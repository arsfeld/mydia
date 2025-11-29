# Managing Libraries

Libraries are the core of Mydia's media organization system. Each library represents a collection of media files in a specific directory.

## Library Types

| Type | Description | Features |
|------|-------------|----------|
| **Movies** | Feature films | Full metadata, downloads, quality profiles |
| **Series** | TV shows with seasons/episodes | Episode tracking, air dates, season monitoring |
| **Mixed** | Combined movies and TV shows | Both movie and series features |
| **Music** | Music collections | File scanning only (experimental) |
| **Books** | E-books and audiobooks | File scanning only (experimental) |
| **Adult** | Adult content | File scanning only (experimental) |

!!! warning "Experimental Library Types"
    Music, Books, and Adult libraries are highly experimental with minimal functionality. They support basic library scanning and browsing only - no metadata fetching, download automation, or quality profiles.

## Creating Libraries

### Via Environment Variables

Configure libraries at container startup:

```bash
# Default libraries
MOVIES_PATH=/media/library/movies
TV_PATH=/media/library/tv

# Additional libraries using numbered variables
LIBRARY_PATH_1_PATH=/media/music
LIBRARY_PATH_1_TYPE=music

LIBRARY_PATH_2_PATH=/media/books
LIBRARY_PATH_2_TYPE=books
```

### Via Admin UI

1. Navigate to **Admin > Libraries**
2. Click **Add Library**
3. Configure:
   - Name
   - Path
   - Type
   - Quality Profile
   - Monitoring settings

## Library Scanning

Mydia periodically scans your libraries to discover new media and update existing entries.

### Scan Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Scan Interval | Hours between automatic scans | 1 hour |
| Monitored | Enable automatic scanning | true |

### Manual Scanning

Trigger a manual scan from the library page or admin interface.

## Path Management

Mydia uses **relative path storage** for media files:

- **Flexible Relocation** - Change library root paths without breaking file references
- **Path Independence** - Database records are portable
- **Automatic Migration** - Paths convert automatically on upgrade

### Configuration Priority

1. Environment variables (highest)
2. Admin UI (database settings)
3. YAML configuration file
4. Schema defaults (lowest)

## Next Steps

- [Adding Media](adding-media.md) - Import media into your libraries
- [Quality Profiles](quality-profiles.md) - Configure download quality
