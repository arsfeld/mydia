# Development Setup

Set up a local development environment for Mydia.

## Prerequisites

- Docker and Docker Compose
- Git

## Quick Start with Docker

The recommended development approach uses Docker Compose with the `./dev` helper script.

### Clone the Repository

```bash
git clone https://github.com/getmydia/mydia.git
cd mydia
```

### Start Development Environment

```bash
# Start all services
./dev up -d

# Run database migrations
./dev mix ecto.migrate

# View logs for admin password
./dev logs | grep "DEFAULT ADMIN USER CREATED" -A 10
```

Access the application at [http://localhost:4000](http://localhost:4000).

## The `./dev` Script

The `./dev` script provides convenient wrappers for common commands:

### Service Management

```bash
./dev up -d       # Start services in background
./dev down        # Stop services
./dev restart     # Restart services
./dev logs -f     # Follow application logs
```

### Interactive Shells

```bash
./dev shell       # Open shell in app container
./dev iex         # Open IEx console
./dev bash        # Open bash shell
```

### Mix Commands

```bash
./dev mix <args>          # Run any mix command
./dev mix ecto.migrate    # Run migrations
./dev mix deps.get        # Fetch dependencies
./dev mix test            # Run tests
./dev mix format          # Format code
```

### Shortcuts

```bash
./dev test        # Run tests
./dev format      # Format code
./dev deps.get    # Fetch dependencies
./dev ecto.migrate # Run migrations
```

Run `./dev` without arguments to see all available commands.

## Local Setup (Without Docker)

For development without Docker:

### Prerequisites

- Elixir 1.16+
- Erlang 26+
- Node.js 18+
- SQLite 3

### Setup

```bash
# Install dependencies
mix setup

# Start Phoenix server
mix phx.server
```

Access at [http://localhost:4000](http://localhost:4000).

## Configuration

### Custom Docker Compose

Create `compose.override.yml` for custom configurations:

```bash
cp compose.override.yml.example compose.override.yml
```

Add services like Transmission, Prowlarr, or Jackett as needed.

### Environment Variables

For development, most defaults work fine. See [Environment Variables](../reference/environment-variables.md) for options.

## Code Quality

### Pre-commit Checks

Run all quality checks before committing:

```bash
./dev mix precommit
```

This runs:

- Code compilation (warnings as errors)
- Code formatting check
- Credo static analysis
- Full test suite

### Install Git Hooks

Automatic pre-commit hooks:

```bash
./scripts/install-git-hooks.sh
```

The hook runs `mix format --check-formatted` before each commit.

### Manual Checks

```bash
# Format code
./dev mix format

# Run Credo
./dev mix credo

# Compile with warnings
./dev mix compile --warnings-as-errors

# Run tests
./dev mix test
```

## Project Structure

```
mydia/
├── assets/           # Frontend assets (JS, CSS)
├── config/           # Configuration files
├── lib/
│   ├── mydia/        # Business logic
│   └── mydia_web/    # Web layer (LiveViews, controllers)
├── priv/
│   ├── repo/         # Database migrations
│   └── static/       # Static assets
└── test/             # Test files
```

## Useful Commands

### Database

```bash
./dev mix ecto.create      # Create database
./dev mix ecto.migrate     # Run migrations
./dev mix ecto.rollback    # Rollback last migration
./dev mix ecto.reset       # Drop, create, and migrate
```

### Testing

```bash
./dev mix test                    # Run all tests
./dev mix test test/path/to/test.exs  # Run specific test
./dev mix test --failed           # Re-run failed tests
```

### Debugging

```bash
./dev iex                         # Interactive Elixir console
./dev logs -f                     # Follow logs
```

## Next Steps

- [Testing](testing.md) - Unit and integration testing
- [E2E Testing](e2e-testing.md) - Browser-based testing
- [Architecture](architecture.md) - System design overview
