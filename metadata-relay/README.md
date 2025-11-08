# Metadata Relay Service

A caching proxy service for TMDB and TVDB APIs built with Elixir, Plug, and Bandit.

## Overview

The Metadata Relay Service acts as an intermediary between the Mydia application and external metadata providers (TMDB and TVDB). It provides:

- **Caching**: Reduces API calls to external services and improves response times
- **Rate Limiting Protection**: Prevents hitting API rate limits
- **API Key Management**: Centralizes API key handling
- **High Performance**: Built on Bandit HTTP server for excellent throughput

## Technology Stack

- **Elixir**: Functional programming language with OTP supervision
- **Bandit**: Fast, lightweight HTTP/1.1 and HTTP/2 server
- **Plug**: Composable web middleware
- **Req**: Modern HTTP client
- **Cachex**: Powerful in-memory caching with TTL and LRU
- **Jason**: JSON encoding/decoding

## Local Development

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Docker and Docker Compose (alternative to local Elixir install)

### Using Docker (Recommended)

1. **Build the container**:
   ```bash
   docker-compose build
   ```

2. **Start the service**:
   ```bash
   docker-compose up
   ```

3. **Run in detached mode**:
   ```bash
   docker-compose up -d
   ```

4. **View logs**:
   ```bash
   docker-compose logs -f relay
   ```

5. **Stop the service**:
   ```bash
   docker-compose down
   ```

### Using Local Elixir

1. **Install dependencies**:
   ```bash
   mix deps.get
   ```

2. **Run the server**:
   ```bash
   mix run --no-halt
   ```

3. **Run with iex (interactive shell)**:
   ```bash
   iex -S mix
   ```

### Testing

Run the test suite:
```bash
mix test
```

Run tests with coverage:
```bash
mix test --cover
```

### Code Formatting

Format code according to project standards:
```bash
mix format
```

## Configuration

The service is configured via environment variables:

- `PORT`: HTTP port (default: 4000)
- `TMDB_API_KEY`: API key for The Movie Database
- `TVDB_API_KEY`: API key for TheTVDB

### Development

Create a `.env` file in the project root:
```bash
PORT=4000
TMDB_API_KEY=your_tmdb_key_here
TVDB_API_KEY=your_tvdb_key_here
```

### Production

Environment variables are passed via Fly.io secrets or container environment.

## API Endpoints

### Health Check

```
GET /health
```

Returns service status and version:
```json
{
  "status": "ok",
  "service": "metadata-relay",
  "version": "0.1.0"
}
```

### TMDB Endpoints

(To be implemented in task 117.2)

### TVDB Endpoints

(To be implemented in task 117.3)

## Project Structure

```
metadata-relay/
├── lib/
│   ├── metadata_relay/
│   │   ├── application.ex     # OTP application supervisor
│   │   └── router.ex          # HTTP router with Plug
│   └── metadata_relay.ex      # Main module
├── config/
│   ├── config.exs             # Base configuration
│   ├── dev.exs                # Development config
│   ├── test.exs               # Test config
│   ├── prod.exs               # Production config
│   └── runtime.exs            # Runtime environment config
├── test/
│   └── test_helper.exs        # Test configuration
├── mix.exs                    # Project definition and dependencies
├── Dockerfile                 # Container image definition
├── docker-compose.yml         # Local development setup
└── README.md                  # This file
```

## Development Workflow

1. Make changes to source files in `lib/`
2. Run `mix format` to format code
3. Run `mix test` to ensure tests pass
4. Test manually by running the server and making HTTP requests

## Next Steps

- [ ] Implement TMDB proxy endpoints (task 117.2)
- [ ] Implement TVDB proxy endpoints with authentication (task 117.3)
- [ ] Add caching layer with Cachex (task 117.4)
- [ ] Create production Docker configuration (task 117.5)
- [ ] Deploy to Fly.io (task 117.6)
- [ ] Update Mydia to use self-hosted relay (task 117.7)
- [ ] Add monitoring and logging (task 117.8)

## License

Same as the main Mydia project.
