{
  description = "Mydia - Self-hosted media management application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # BEAM packages (Erlang/Elixir)
        beamPackages = pkgs.beam.packages.erlang_27;

        # Import Mix dependencies from deps.nix
        mixNixDeps = import ./deps.nix {
          lib = pkgs.lib;
          beamPackages = beamPackages;
          inherit pkgs;
        };

        # Heroicons (git dependency, not an Elixir package)
        heroicons = pkgs.fetchFromGitHub {
          owner = "tailwindlabs";
          repo = "heroicons";
          rev = "v2.2.0";
          hash = "sha256-Jcxr1fSbmXO9bZKeg39Z/zVN0YJp17TX3LH5Us4lsZU=";
        };

        # Platform-specific binary names for esbuild/tailwind
        platformSuffix = {
          "x86_64-linux" = "linux-x64";
          "aarch64-linux" = "linux-arm64";
          "x86_64-darwin" = "darwin-x64";
          "aarch64-darwin" = "darwin-arm64";
        }.${system} or "linux-x64";

      in
      {
        # Production package
        packages.default = beamPackages.mixRelease {
          pname = "mydia";
          version = "0.6.0";
          src = ./.;

          mixNixDeps = mixNixDeps;

          # Build-time dependencies
          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.git
          ];

          # Runtime dependencies for NIFs
          buildInputs = [
            pkgs.sqlite
            pkgs.ffmpeg
          ];

          # Don't strip symbols (needed for Erlang NIFs)
          dontStrip = true;

          # Set HOME to a writable directory for elixir_make cache
          HOME = "/tmp";

          # Remove dev/test dependencies from the build
          removeCookie = false;

          # Configure asset compilation
          preBuild = ''
            # Copy heroicons to deps (git dependency, not handled by mixNixDeps)
            mkdir -p deps/heroicons
            cp -r ${heroicons}/optimized deps/heroicons/

            # Install npm dependencies
            cd assets
            npm ci --ignore-scripts
            cd ..

            # Link platform-specific binaries for esbuild and tailwind
            mkdir -p _build
            ln -sf ${pkgs.esbuild}/bin/esbuild _build/esbuild-${platformSuffix}
            ln -sf ${pkgs.tailwindcss}/bin/tailwindcss _build/tailwind-${platformSuffix}

            # Build assets
            export MIX_ENV=prod
            mix assets.deploy
          '';

          # Set environment for production
          MIX_ENV = "prod";

          # Post-install: wrap the release binary to include runtime deps
          postInstall = ''
            wrapProgram $out/bin/mydia \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg pkgs.sqlite ]}
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Elixir/Erlang (latest)
            pkgs.elixir
            pkgs.erlang

            # Node.js for assets (latest)
            pkgs.nodejs

            # Database
            pkgs.sqlite

            # Media processing
            pkgs.ffmpeg

            # Build tools for NIFs (bcrypt_elixir, argon2_elixir, membrane)
            pkgs.gcc
            pkgs.gnumake
            pkgs.pkg-config

            # File watching (for live reload)
            pkgs.inotify-tools

            # Browser testing with Wallaby
            pkgs.chromium
            pkgs.chromedriver

            # Git (needed for deps)
            pkgs.git

            # Useful development utilities
            pkgs.curl
          ];

          shellHook = ''
            # Configure Mix and Hex to use local directories
            export MIX_HOME="$PWD/.nix-mix"
            export HEX_HOME="$PWD/.nix-hex"
            export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"

            # Enable IEx history
            export ERL_AFLAGS="-kernel shell_history enabled"

            # Configure locale for Elixir
            export LANG="C.UTF-8"
            export LC_ALL="C.UTF-8"

            # For Wallaby browser tests
            export CHROME_PATH="${pkgs.chromium}/bin/chromium"
            export CHROMEDRIVER_PATH="${pkgs.chromedriver}/bin/chromedriver"

            # Ensure hex and rebar are installed (only show output in interactive shells)
            if [ ! -d "$MIX_HOME" ]; then
              if [ -t 1 ]; then
                echo "Setting up Mix and Hex..."
                mix local.hex --force
                mix local.rebar --force
              else
                mix local.hex --force >/dev/null 2>&1
                mix local.rebar --force >/dev/null 2>&1
              fi
            fi

            # Only show welcome message in interactive shells
            if [ -t 1 ]; then
              echo ""
              echo "Mydia development environment loaded!"
              echo "  Elixir: $(elixir --version | head -n 1)"
              echo "  Erlang: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>&1)"
              echo "  Node.js: $(node --version)"
              echo ""
              echo "Run 'mix deps.get' to install dependencies"
              echo "Run 'mix phx.server' to start the development server"
              echo ""
            fi
          '';
        };
      }
    );
}
