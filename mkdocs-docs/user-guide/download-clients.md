# Download Clients

Download clients handle the actual downloading of media files. Mydia supports both torrent and usenet clients.

## Supported Clients

### Torrent Clients

| Client | Protocol | Features |
|--------|----------|----------|
| qBittorrent | HTTP API | Categories, labels, seeding |
| Transmission | RPC | Categories, seeding |

### Usenet Clients

| Client | Protocol | Features |
|--------|----------|----------|
| SABnzbd | HTTP API | Categories, priorities |
| NZBGet | JSON-RPC | Categories, priorities |

## Adding Download Clients

### Via Admin UI

1. Navigate to **Admin > Download Clients**
2. Click **Add Download Client**
3. Select client type
4. Enter connection details
5. Test connection
6. Save

### Via Environment Variables

Configure clients at container startup:

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

# SABnzbd
DOWNLOAD_CLIENT_3_NAME=SABnzbd
DOWNLOAD_CLIENT_3_TYPE=sabnzbd
DOWNLOAD_CLIENT_3_HOST=sabnzbd
DOWNLOAD_CLIENT_3_PORT=8080
DOWNLOAD_CLIENT_3_API_KEY=your-sabnzbd-api-key

# NZBGet
DOWNLOAD_CLIENT_4_NAME=NZBGet
DOWNLOAD_CLIENT_4_TYPE=nzbget
DOWNLOAD_CLIENT_4_HOST=nzbget
DOWNLOAD_CLIENT_4_PORT=6789
DOWNLOAD_CLIENT_4_USERNAME=nzbget
DOWNLOAD_CLIENT_4_PASSWORD=tegbzn6789
```

## Configuration Options

| Option | Description | Example |
|--------|-------------|---------|
| Name | Display name | `qBittorrent` |
| Type | Client type | `qbittorrent` |
| Host | Hostname or IP | `192.168.1.100` |
| Port | Client port | `8080` |
| Username | Auth username | `admin` |
| Password | Auth password | `secret` |
| API Key | API key (SABnzbd) | `abc123` |
| Use SSL | Enable HTTPS | `true` |
| Category | Default category | `mydia` |
| Priority | Client priority | `1` |
| Download Directory | Output directory | `/downloads` |

## Client Priority

When multiple clients are configured, priority determines which client is used:

- Higher priority = preferred
- If primary client fails, falls back to lower priority clients

## Categories

Categories help organize downloads:

- Configure a category in your download client
- Set the same category in Mydia
- Downloads are tagged with this category

## Download Directory

Configure where downloads are saved:

- Set in download client settings
- Ensure Mydia can access this directory
- Use same filesystem as library for hardlinks

## Testing Connection

Always test connections before saving:

1. Click **Test Connection**
2. Verify successful connection
3. Check for any warnings

## Next Steps

- [Indexers](indexers.md) - Configure release searching
- [Environment Variables](../reference/environment-variables.md) - All configuration options
