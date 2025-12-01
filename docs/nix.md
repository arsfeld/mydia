# Nix Development and NixOS Deployment

This guide covers using Nix for development and deploying Mydia on NixOS.

## Development with Nix

### Prerequisites

- Nix with flakes enabled
- Git

To enable flakes, add this to your `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### Quick Start

Enter the development shell:

```bash
nix develop
```

This provides:
- Elixir and Erlang
- Node.js
- SQLite
- FFmpeg
- Chromium/ChromeDriver (for testing)
- All required build tools

### First-Time Setup

```bash
nix develop
mix deps.get
mix ecto.setup
mix phx.server
```

### Updating Dependencies

After modifying `mix.exs` or `mix.lock`:

```bash
# Update deps.nix from mix.lock
mix2nix > deps.nix
```

## Building from Source

### Build the Release

```bash
nix build
```

The result is a fully self-contained Erlang release at `./result`.

### Run the Release Locally

```bash
# Set required environment variables
export SECRET_KEY_BASE=$(openssl rand -base64 48)
export DATABASE_PATH=/tmp/mydia.db
export PHX_HOST=localhost
export PORT=4000
export PHX_SERVER=true

# Run migrations
./result/bin/mydia eval "Ecto.Migrator.run(Mydia.Repo, :up, all: true)"

# Start the server
./result/bin/mydia start
```

## NixOS Deployment

### Adding the Flake

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mydia.url = "github:owner/mydia";  # Replace with actual repo
  };

  outputs = { self, nixpkgs, mydia }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        mydia.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Minimal Configuration

```nix
{ pkgs, ... }:
{
  services.mydia = {
    enable = true;
    package = pkgs.mydia;  # or inputs.mydia.packages.${system}.default

    host = "mydia.example.com";
    port = 4000;

    secretKeyBaseFile = "/run/secrets/mydia/secret_key_base";

    mediaLibraries = [
      "/mnt/media/movies"
      "/mnt/media/tv"
    ];
  };
}
```

### Full Configuration Example

See [examples/nixos/full.nix](../examples/nixos/full.nix) for a complete example.

```nix
{ config, pkgs, ... }:
{
  services.mydia = {
    enable = true;
    package = pkgs.mydia;

    # Web server
    host = "mydia.example.com";
    port = 4000;
    listenAddress = "0.0.0.0";
    openFirewall = true;

    # Database
    databasePath = "/var/lib/mydia/mydia.db";
    dataDir = "/var/lib/mydia";

    # Secrets
    secretKeyBaseFile = "/run/secrets/mydia/secret_key_base";
    guardianSecretKeyFile = "/run/secrets/mydia/guardian_secret";

    # Media
    mediaLibraries = [
      "/mnt/media/movies"
      "/mnt/media/tv"
      "/mnt/media/anime"
    ];

    # Logging
    logLevel = "info";  # debug, info, warning, error

    # OIDC Authentication
    oidc = {
      enable = true;
      issuer = "https://auth.example.com/application/o/mydia/";
      clientIdFile = "/run/secrets/mydia/oidc_client_id";
      clientSecretFile = "/run/secrets/mydia/oidc_client_secret";
      scopes = [ "openid" "profile" "email" ];
    };

    # Download Clients
    downloadClients = {
      qbit = {
        type = "qbittorrent";
        host = "localhost";
        port = 8080;
        username = "admin";
        passwordFile = "/run/secrets/mydia/qbittorrent_password";
      };

      transmission = {
        type = "transmission";
        host = "192.168.1.100";
        port = 9091;
        username = "transmission";
        passwordFile = "/run/secrets/mydia/transmission_password";
      };
    };

    # FlareSolverr (for bypassing Cloudflare)
    flareSolverr = {
      enable = true;
      url = "http://localhost:8191";
      timeout = 60000;
      maxTimeout = 120000;
    };

    # Extra environment variables
    extraEnvironment = {
      ENABLE_PLAYBACK = "true";
    };
  };
}
```

### Secrets Management

#### Using agenix

```nix
# secrets.nix
{
  "mydia-secret-key.age".publicKeys = [ ... ];
  "mydia-guardian-secret.age".publicKeys = [ ... ];
  "mydia-oidc-client-id.age".publicKeys = [ ... ];
  "mydia-oidc-client-secret.age".publicKeys = [ ... ];
}

# configuration.nix
{ config, ... }:
{
  age.secrets = {
    mydia-secret-key.file = ./secrets/mydia-secret-key.age;
    mydia-guardian-secret.file = ./secrets/mydia-guardian-secret.age;
    mydia-oidc-client-id.file = ./secrets/mydia-oidc-client-id.age;
    mydia-oidc-client-secret.file = ./secrets/mydia-oidc-client-secret.age;
  };

  services.mydia = {
    enable = true;
    secretKeyBaseFile = config.age.secrets.mydia-secret-key.path;
    guardianSecretKeyFile = config.age.secrets.mydia-guardian-secret.path;
    oidc = {
      enable = true;
      clientIdFile = config.age.secrets.mydia-oidc-client-id.path;
      clientSecretFile = config.age.secrets.mydia-oidc-client-secret.path;
    };
  };
}
```

#### Using sops-nix

```nix
# configuration.nix
{ config, ... }:
{
  sops.secrets = {
    "mydia/secret_key_base" = {};
    "mydia/guardian_secret" = {};
    "mydia/oidc_client_id" = {};
    "mydia/oidc_client_secret" = {};
  };

  services.mydia = {
    enable = true;
    secretKeyBaseFile = config.sops.secrets."mydia/secret_key_base".path;
    guardianSecretKeyFile = config.sops.secrets."mydia/guardian_secret".path;
    oidc = {
      enable = true;
      clientIdFile = config.sops.secrets."mydia/oidc_client_id".path;
      clientSecretFile = config.sops.secrets."mydia/oidc_client_secret".path;
    };
  };
}
```

#### Generating Secrets

```bash
# Generate SECRET_KEY_BASE
openssl rand -base64 48 > /path/to/secret_key_base

# Generate GUARDIAN_SECRET_KEY (can be same as SECRET_KEY_BASE)
openssl rand -base64 48 > /path/to/guardian_secret
```

### Reverse Proxy Configuration

#### With nginx

```nix
services.nginx = {
  enable = true;
  virtualHosts."mydia.example.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
};
```

## Configuration Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the Mydia service |
| `package` | package | - | The Mydia package to use |
| `port` | port | `4000` | Port for the web interface |
| `host` | string | `"localhost"` | Host for URL generation |
| `listenAddress` | string | `"127.0.0.1"` | IP address to listen on |
| `databasePath` | path | `"/var/lib/mydia/mydia.db"` | Path to SQLite database |
| `dataDir` | path | `"/var/lib/mydia"` | Data directory |
| `mediaLibraries` | list of paths | `[]` | Media library paths |
| `secretKeyBaseFile` | path | - | Path to SECRET_KEY_BASE file |
| `guardianSecretKeyFile` | path | `null` | Path to GUARDIAN_SECRET_KEY file |
| `user` | string | `"mydia"` | User account to run as |
| `group` | string | `"mydia"` | Group to run as |
| `openFirewall` | bool | `false` | Open firewall for web interface |
| `logLevel` | enum | `"info"` | Log level (debug/info/warning/error) |
| `oidc.enable` | bool | `false` | Enable OIDC authentication |
| `oidc.issuer` | string | - | OIDC issuer URL |
| `oidc.clientIdFile` | path | - | Path to OIDC client ID file |
| `oidc.clientSecretFile` | path | - | Path to OIDC client secret file |
| `oidc.scopes` | list of strings | `["openid" "profile" "email"]` | OIDC scopes |
| `downloadClients` | attrset | `{}` | Download clients configuration |
| `flareSolverr.enable` | bool | `false` | Enable FlareSolverr |
| `flareSolverr.url` | string | `"http://localhost:8191"` | FlareSolverr URL |
| `extraEnvironment` | attrset | `{}` | Extra environment variables |

## Troubleshooting

### Service Won't Start

Check the logs:

```bash
journalctl -u mydia -f
```

### Database Migration Errors

The service runs migrations automatically. If they fail, check:

```bash
# Check if database directory exists and is writable
ls -la /var/lib/mydia/

# Check database file permissions
ls -la /var/lib/mydia/mydia.db
```

### Permission Denied on Media Libraries

Ensure the mydia user has read access:

```bash
# Add mydia user to media group
usermod -a -G media mydia

# Or adjust permissions
chmod o+rx /mnt/media
```

### OIDC Authentication Issues

1. Verify the issuer URL is correct and accessible
2. Check that client ID and secret files are readable by the mydia user
3. Review logs for OIDC-related errors

### Download Client Connection Issues

1. Verify the download client is running and accessible
2. Check firewall rules if the client is on a different host
3. Verify credentials are correct
