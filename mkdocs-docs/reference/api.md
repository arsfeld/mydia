# API Reference

!!! info "Coming Soon"
    API documentation is planned for a future release. Mydia currently provides a web interface for all functionality.

## Current State

Mydia does not currently expose a public REST API. All functionality is accessible through the Phoenix LiveView web interface.

## Planned Features

Future API support may include:

- REST API for media management
- WebSocket events for real-time updates
- API key authentication
- Rate limiting

## Internal APIs

Mydia uses internal APIs for:

- Download client communication (qBittorrent, Transmission, SABnzbd, NZBGet)
- Indexer queries (Prowlarr, Jackett)
- Metadata fetching (via metadata-relay service)

These are implementation details and not intended for external use.

## Integration Options

Currently, you can integrate with Mydia through:

1. **Download Clients** - Configure in Admin UI
2. **Indexers** - Configure in Admin UI
3. **OIDC/SSO** - Authenticate via external identity providers

## Contributing

If you're interested in API development, check the [Development](../development/setup.md) documentation and consider contributing to the project.
