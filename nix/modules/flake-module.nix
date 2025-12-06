{self, ...}: {
  flake.nixosModules.default = {
    config,
    pkgs,
    lib,
    utils,
    ...
  }: let
    cfg = config.services.mydia;
    dbUrl = self.lib.url.parse cfg.database.uri;
    inherit (lib) mkEnableOption mkPackageOption mkOption mkIf types literalExpression optional optionals optionalString;

    # Download client submodule type
    downloadClientType = types.submodule {
      options = {
        type = mkOption {
          type = types.enum ["qbittorrent" "transmission" "sabnzbd" "nzbget"];
          description = "Type of download client";
        };
        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "Host of the download client";
        };
        port = mkOption {
          type = types.port;
          description = "Port of the download client";
        };
        username = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Username for authentication";
        };
        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing the password";
        };
        useSsl = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to use SSL/TLS";
        };
      };
    };
  in {
    options.services.mydia = {
      enable = mkEnableOption "Mydia media manager";

      package = mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} (
        if cfg.database.type == "sqlite"
        then "mydia"
        else "mydia-pg"
      ) {};

      port = mkOption {
        type = types.port;
        default = 4000;
        description = "Port for the web interface";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "Host to bind to (used for URL generation)";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "IP address to listen on";
      };

      database = mkOption {
        type = types.submodule {
          options = {
            type = mkOption {
              type = types.enum ["sqlite" "postgres"];
              default = "sqlite";
              description = ''
                Which database type to use.
              '';
            };

            uri = mkOption {
              type = types.str;
              default = "file:${cfg.dataDir}/mydia.db";
              description = ''
                How to reach the database
              '';
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                Path to a file containing the password for the database.
              '';
              example = "/run/secrets/mydia/postgres_password";
            };
          };
        };
        default = {
          type = "sqlite";
          uri = "file:///var/lib/mydia/mydia.db";
        };
        description = '''';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/mydia";
        description = "Directory for Mydia data files";
      };

      mediaLibraries = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "List of media library paths that Mydia needs read access to";
        example = ["/mnt/media/movies" "/mnt/media/tv"];
      };

      secretKeyBaseFile = mkOption {
        type = types.path;
        description = ''
          Path to a file containing the SECRET_KEY_BASE.
          Generate with: `mix phx.gen.secret` or `openssl rand -base64 48`
        '';
        example = "/run/secrets/mydia/secret_key_base";
      };

      guardianSecretKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to a file containing the GUARDIAN_SECRET_KEY for JWT tokens.
          If not set, SECRET_KEY_BASE will be used.
        '';
        example = "/run/secrets/mydia/guardian_secret";
      };

      user = mkOption {
        type = types.str;
        default = "mydia";
        description = "User account under which Mydia runs";
      };

      group = mkOption {
        type = types.str;
        default = "mydia";
        description = "Group under which Mydia runs";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to open the firewall for the web interface";
      };

      logLevel = mkOption {
        type = types.enum ["debug" "info" "warning" "error"];
        default = "info";
        description = "Log level for the application";
      };

      # OIDC Authentication options
      oidc = {
        enable = mkEnableOption "OIDC authentication";

        issuer = mkOption {
          type = types.str;
          description = "OIDC issuer URL";
          example = "https://auth.example.com/application/o/mydia/";
        };

        discoveryDocumentUri = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "OIDC discovery document URI (defaults to issuer/.well-known/openid-configuration)";
        };

        clientIdFile = mkOption {
          type = types.path;
          description = "Path to file containing the OIDC client ID";
          example = "/run/secrets/mydia/oidc_client_id";
        };

        clientSecretFile = mkOption {
          type = types.path;
          description = "Path to file containing the OIDC client secret";
          example = "/run/secrets/mydia/oidc_client_secret";
        };

        scopes = mkOption {
          type = types.listOf types.str;
          default = ["openid" "profile" "email"];
          description = "OIDC scopes to request";
        };
      };

      # Download client options
      downloadClients = mkOption {
        type = types.attrsOf downloadClientType;
        default = {};
        description = "Download clients configuration";
        example = literalExpression ''
          {
            main = {
              type = "qbittorrent";
              host = "localhost";
              port = 8080;
              username = "admin";
              passwordFile = "/run/secrets/mydia/qbittorrent_password";
            };
          }
        '';
      };

      # FlareSolverr options
      flareSolverr = {
        enable = mkEnableOption "FlareSolverr integration";

        url = mkOption {
          type = types.str;
          default = "http://localhost:8191";
          description = "FlareSolverr URL";
        };

        timeout = mkOption {
          type = types.int;
          default = 60000;
          description = "FlareSolverr timeout in milliseconds";
        };

        maxTimeout = mkOption {
          type = types.int;
          default = 120000;
          description = "FlareSolverr maximum timeout in milliseconds";
        };
      };

      extraEnvironment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra environment variables to pass to the service";
        example = {
          ENABLE_PLAYBACK = "true";
        };
      };
    };

    config = mkIf cfg.enable {
      warnings = [
        (mkIf (cfg.database.type == "postgres" && dbUrl?password && dbUrl.password != null) ''
          Passing the password via the URL is strongly discouraged.
          As this would expose your password in both your git,
          as well as in the nix store on the target machine.

          Instead we recommend you instead use sops-nix/agenix to manage the password for you.
        '')
      ];

      assertions = [
        {
          assertion = cfg.database.type == "postgres" -> cfg.database.passwordFile != null || (dbUrl?password && dbUrl.password != null);
          message = ''
            The password for postgres is required,
            either set it with `config.services.mydia.database.passwordFile`,
            or as the password parameter in the URL (not recommended).
          '';
        }
      ];

      systemd.services.mydia = {
        description = "Mydia Media Manager";
        wantedBy = ["multi-user.target"];
        after =
          ["network.target"]
          ++ lib.optional (config.services.mydia.database.type == "postgres") "postgres.target";

        environment =
          {
            PORT = toString cfg.port;
            PHX_HOST = cfg.host;
            PHX_IP = cfg.listenAddress;
            PHX_SERVER = "true";
            LOG_LEVEL = cfg.logLevel;
            RELEASE_COOKIE = "mydia_nixos";
            RELEASE_DISTRIBUTION = "none";
            HOME = cfg.dataDir;
            DATABASE_TYPE = cfg.database.type;
          }
          // lib.optionalAttrs (cfg.database.type == "sqlite") {
            DATABASE_PATH = dbUrl.path;
          }
          // lib.optionalAttrs (cfg.database.type == "postgres")
          {
            DATABASE_HOST = dbUrl.hostName;
            DATABASE_PORT = toString dbUrl.port;
            DATABASE_NAME = (dbUrl.path or "/mydia") |> lib.substring 1 (-1) |> lib.splitString "/" |> lib.head;
            DATABASE_USER = dbUrl.user or "mydia";
            DATABASE_PASSWORD = dbUrl.password or "";
            DATABASE_SSL_MODE = dbUrl.queryParams.sslmode or "verify";
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OIDC_ISSUER = cfg.oidc.issuer;
            OIDC_SCOPES = lib.concatStringsSep " " cfg.oidc.scopes;
          }
          // lib.optionalAttrs (cfg.oidc.enable && cfg.oidc.discoveryDocumentUri != null) {
            OIDC_DISCOVERY_DOCUMENT_URI = cfg.oidc.discoveryDocumentUri;
          }
          // lib.optionalAttrs cfg.flareSolverr.enable {
            FLARESOLVERR_ENABLED = "true";
            FLARESOLVERR_URL = cfg.flareSolverr.url;
            FLARESOLVERR_TIMEOUT = toString cfg.flareSolverr.timeout;
            FLARESOLVERR_MAX_TIMEOUT = toString cfg.flareSolverr.maxTimeout;
          }
          // cfg.extraEnvironment;

        path = [cfg.package pkgs.ffmpeg];

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.dataDir;

          # Run migrations before starting
          ExecStartPre = [
            (pkgs.writeShellScript "mydia-migrate" ''
              set -euo pipefail

              # Load secrets
              if [ -f "$CREDENTIALS_DIRECTORY/SECRET_KEY_BASE" ]; then
                export SECRET_KEY_BASE=$(cat "$CREDENTIALS_DIRECTORY/SECRET_KEY_BASE")
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/GUARDIAN_SECRET_KEY" ]; then
                export GUARDIAN_SECRET_KEY=$(cat "$CREDENTIALS_DIRECTORY/GUARDIAN_SECRET_KEY")
              fi

              # Create database directory if it doesn't exist
              mkdir -p "$(dirname "${cfg.database.uri}")"

              # Run migrations
              ${cfg.package}/bin/mydia eval "Ecto.Migrator.run(Mydia.Repo, :up, all: true)"
            '')
          ];

          ExecStart = let
            # Build credential loading script
            loadSecrets = ''
              # Load core secrets
              if [ -f "$CREDENTIALS_DIRECTORY/SECRET_KEY_BASE" ]; then
                export SECRET_KEY_BASE=$(cat "$CREDENTIALS_DIRECTORY/SECRET_KEY_BASE")
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/GUARDIAN_SECRET_KEY" ]; then
                export GUARDIAN_SECRET_KEY=$(cat "$CREDENTIALS_DIRECTORY/GUARDIAN_SECRET_KEY")
              fi
            '';

            loadOidcSecrets = optionalString cfg.oidc.enable ''
              # Load OIDC secrets
              if [ -f "$CREDENTIALS_DIRECTORY/OIDC_CLIENT_ID" ]; then
                export OIDC_CLIENT_ID=$(cat "$CREDENTIALS_DIRECTORY/OIDC_CLIENT_ID")
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/OIDC_CLIENT_SECRET" ]; then
                export OIDC_CLIENT_SECRET=$(cat "$CREDENTIALS_DIRECTORY/OIDC_CLIENT_SECRET")
              fi
            '';

            loadDownloadClientSecrets = lib.concatStringsSep "\n" (lib.mapAttrsToList (
                name: client:
                  optionalString (client.passwordFile != null) ''
                    # Load ${name} download client password
                    if [ -f "$CREDENTIALS_DIRECTORY/DOWNLOAD_CLIENT_${lib.toUpper name}_PASSWORD" ]; then
                      export DOWNLOAD_CLIENT_${lib.toUpper name}_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/DOWNLOAD_CLIENT_${lib.toUpper name}_PASSWORD")
                    fi
                  ''
              )
              cfg.downloadClients);

            # Build download client environment exports
            downloadClientEnvs = lib.concatStringsSep "\n" (lib.mapAttrsToList (
                name: client: let
                  upperName = lib.toUpper name;
                  proto =
                    if client.useSsl
                    then "https"
                    else "http";
                in ''
                  export DOWNLOAD_CLIENT_${upperName}_TYPE="${client.type}"
                  export DOWNLOAD_CLIENT_${upperName}_URL="${proto}://${client.host}:${toString client.port}"
                  ${optionalString (client.username != null) ''export DOWNLOAD_CLIENT_${upperName}_USERNAME="${client.username}"''}
                ''
              )
              cfg.downloadClients);
          in
            pkgs.writeShellScript "mydia-start" ''
              set -euo pipefail

              ${loadSecrets}
              ${loadOidcSecrets}
              ${loadDownloadClientSecrets}
              ${downloadClientEnvs}

              exec ${cfg.package}/bin/mydia start
            '';

          ExecStop = "${cfg.package}/bin/mydia stop";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStartSec = 60;

          # Secrets via LoadCredential (not stored in Nix store)
          LoadCredential =
            ["SECRET_KEY_BASE:${cfg.secretKeyBaseFile}"]
            ++ optional (cfg.guardianSecretKeyFile != null)
            "GUARDIAN_SECRET_KEY:${cfg.guardianSecretKeyFile}"
            ++ optional (cfg.database.passwordFile != null)
            "DATABASE_PASSWORD:${cfg.database.passwordFile}"
            ++ optionals cfg.oidc.enable [
              "OIDC_CLIENT_ID:${cfg.oidc.clientIdFile}"
              "OIDC_CLIENT_SECRET:${cfg.oidc.clientSecretFile}"
            ]
            ++ lib.concatLists (lib.mapAttrsToList (
                name: client:
                  optional (client.passwordFile != null)
                  "DOWNLOAD_CLIENT_${lib.toUpper name}_PASSWORD:${client.passwordFile}"
              )
              cfg.downloadClients);

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          MemoryDenyWriteExecute = false; # Required for BEAM JIT
          LockPersonality = true;
          SystemCallArchitectures = "native";

          # Writable paths
          ReadWritePaths = [cfg.dataDir] ++ cfg.mediaLibraries;
          ReadOnlyPaths = cfg.mediaLibraries;

          # State directory
          StateDirectory = "mydia";
          StateDirectoryMode = "0750";
        };
      };

      services.postgresql = mkIf (cfg.database.type == "postgres") {
        enable = true;
        ensureDatabases = ["mydia"];
        ensureUsers = [
          {
            name = "mydia";
            ensureDBOwnership = true;
          }
        ];
      };

      # Create user and group
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        description = "Mydia service user";
      };

      users.groups.${cfg.group} = {};

      # Open firewall if requested
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];
    };
  };
}
