{inputs, ...}: {
  perSystem = {
    self',
    system,
    pkgs,
    lib,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Elixir/Erlang (latest)
        elixir
        erlang

        # Node.js for assets (latest)
        nodejs

        # Database
        sqlite

        # Media processing
        ffmpeg

        # Build tools for NIFs (bcrypt_elixir, argon2_elixir, membrane)
        gcc
        gnumake
        pkg-config

        # File watching (for live reload)
        inotify-tools

        # Browser testing with Wallaby
        chromium
        chromedriver

        # Git (needed for deps)
        git

        # Useful development utilities
        curl
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
  };
}
