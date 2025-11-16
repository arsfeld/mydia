# E2E Mock Services

This directory contains mock HTTP servers for external services.

## Purpose

Mock services provide predictable, fast responses from external dependencies:
- Prowlarr API mock
- qBittorrent/Transmission download client mocks
- OIDC provider mock
- Media metadata service mocks

## Implementation

Mock servers should be implemented as lightweight HTTP servers that can be started/stopped during tests:

```typescript
// prowlarr-mock.ts
import express from 'express';

export function createProwlarrMock(port = 9696) {
  const app = express();

  app.get('/api/v1/indexer', (req, res) => {
    res.json([/* mock indexers */]);
  });

  return app.listen(port);
}
```
