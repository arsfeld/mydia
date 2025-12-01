{...}: {
  perSystem = {
    self',
    system,
    pkgs,
    lib,
    ...
  }: let
    # BEAM packages (Erlang/Elixir)
    beamPackages = pkgs.beam.packages.erlang_27;

    # Fine package (needed for lazy_html)
    fineVersion = "0.1.4";
    fineSrc = beamPackages.fetchHex {
      pkg = "fine";
      version = fineVersion;
      sha256 = "be3324cc454a42d80951cf6023b9954e9ff27c6daa255483b3e8d608670303f5";
    };

    # Import Mix dependencies from deps.nix with overrides for Nix sandbox builds
    mixNixDeps = import ../../deps.nix {
      lib = pkgs.lib;
      beamPackages = beamPackages;
      overrides = final: prev: {
        # Bundlex: patch pkg-config for Nix sandbox
        bundlex = prev.bundlex.override {
          postPatch = ''
            substituteInPlace lib/bundlex/toolchain/common/unix/os_deps.ex \
              --replace 'Application.get_env(:bundlex, :disable_precompiled_os_deps, false)' \
                        'Application.get_env(:bundlex, :disable_precompiled_os_deps, true)' \
              --replace 'System.cmd("pkg-config"' \
                        'System.cmd("${pkgs.pkg-config}/bin/pkg-config"' \
              --replace 'System.cmd("which", ["pkg-config"])' \
                        '{"${pkgs.pkg-config}/bin/pkg-config\n", 0}'
          '';
        };

        # lazy_html: prefetch lexbor and configure fine.hpp
        lazy_html = prev.lazy_html.override {
          nativeBuildInputs = [pkgs.cmake pkgs.gnumake pkgs.gcc];

          preConfigure = ''
            mkdir -p _build/c/third_party/lexbor
            cp -r ${lexbor} _build/c/third_party/lexbor/244b84956a6dc7eec293781d051354f351274c46
            chmod -R u+w _build/c/third_party/lexbor

            cp -r ${fineSrc} /build/fine-${fineVersion}
            chmod -R u+w /build/fine-${fineVersion}
          '';

          preBuild = ''
            export HOME=/tmp
            mkdir -p /tmp/.cache/elixir_make
          '';
        };

        # exqlite: needs HOME for elixir_make cache
        exqlite = prev.exqlite.override {
          buildInputs = [pkgs.sqlite];
          preBuild = ''
            export HOME=/tmp
            mkdir -p /tmp/.cache/elixir_make
          '';
        };

        # shmex: needs bunch_native source for bundlex
        shmex = prev.shmex.override {
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            chmod -R u+w deps
          '';
        };

        # unifex: Skip native compilation by removing bundlex from compilers
        unifex = prev.unifex.override {
          postPatch = ''
            # Remove bundlex compiler to skip native compilation
            # Natives will be compiled in the final mixRelease build
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            chmod -R u+w deps
          '';
        };

        # membrane_common_c: Skip native compilation by removing bundlex from compilers
        membrane_common_c = prev.membrane_common_c.override {
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
          '';
        };

        # argon2_elixir: needs HOME for elixir_make cache
        argon2_elixir = prev.argon2_elixir.override {
          preBuild = ''
            export HOME=/tmp
            mkdir -p /tmp/.cache/elixir_make
          '';
        };

        # bcrypt_elixir: needs HOME for elixir_make cache
        bcrypt_elixir = prev.bcrypt_elixir.override {
          preBuild = ''
            export HOME=/tmp
            mkdir -p /tmp/.cache/elixir_make
          '';
        };

        # Membrane plugins: Skip native compilation by removing bundlex from compilers
        membrane_aac_fdk_plugin = prev.membrane_aac_fdk_plugin.override {
          buildInputs = [pkgs.fdk_aac pkgs.ffmpeg_6-headless];
          HOME = "/tmp";
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
            mkdir -p /tmp/.cache/elixir_make
          '';
        };
        membrane_ffmpeg_swresample_plugin = prev.membrane_ffmpeg_swresample_plugin.override {
          buildInputs = [pkgs.ffmpeg_6-headless];
          HOME = "/tmp";
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
            mkdir -p /tmp/.cache/elixir_make
          '';
        };
        membrane_ffmpeg_swscale_plugin = prev.membrane_ffmpeg_swscale_plugin.override {
          buildInputs = [pkgs.ffmpeg_6-headless];
          HOME = "/tmp";
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
            mkdir -p /tmp/.cache/elixir_make
          '';
        };
        membrane_h264_ffmpeg_plugin = prev.membrane_h264_ffmpeg_plugin.override {
          buildInputs = [pkgs.ffmpeg_6-headless];
          HOME = "/tmp";
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
            mkdir -p /tmp/.cache/elixir_make
          '';
        };
        membrane_h265_ffmpeg_plugin = prev.membrane_h265_ffmpeg_plugin.override {
          buildInputs = [pkgs.ffmpeg_6-headless];
          HOME = "/tmp";
          postPatch = ''
            sed -i 's/compilers: \[:bundlex, :unifex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:unifex, :bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
            sed -i 's/compilers: \[:bundlex\] ++ Mix.compilers()/compilers: Mix.compilers()/' mix.exs
          '';
          preConfigure = ''
            mkdir -p deps
            cp -r ${prev.bunch_native.src} deps/bunch_native
            cp -r ${prev.shmex.src} deps/shmex
            cp -r ${prev.unifex.src} deps/unifex
            chmod -R u+w deps
            mkdir -p /tmp/.cache/elixir_make
          '';
        };
      };
    };

    # Heroicons (git dependency, not an Elixir package)
    heroicons = pkgs.fetchFromGitHub {
      owner = "tailwindlabs";
      repo = "heroicons";
      rev = "v2.2.0";
      hash = "sha256-Jcxr1fSbmXO9bZKeg39Z/zVN0YJp17TX3LH5Us4lsZU=";
    };

    # Lexbor (needed for lazy_html NIF compilation)
    lexbor = pkgs.fetchFromGitHub {
      owner = "lexbor";
      repo = "lexbor";
      rev = "244b84956a6dc7eec293781d051354f351274c46";
      hash = "sha256-Oup/lGU8a9Dqfho4Llg39t9Y9n4xfUmGk0772OkpnLQ=";
    };

    # Platform-specific binary names for esbuild/tailwind
    platformSuffix =
      {
        "x86_64-linux" = "linux-x64";
        "aarch64-linux" = "linux-arm64";
        "x86_64-darwin" = "darwin-x64";
        "aarch64-darwin" = "darwin-arm64";
      }.${
        system
      } or "linux-x64";

    # Pre-fetch npm dependencies (required for sandbox build)
    npmDeps = pkgs.fetchNpmDeps {
      src = ../../assets;
      hash = "sha256-NMEudc78qbm1x9+CV4a7z/c+YfMyUD/mYPMwfzYYoVc=";
    };

    # Tailwind CSS v4 binary (not yet in nixpkgs)
    # Needs to be patched for NixOS
    tailwindVersion = "4.1.7";
    tailwindBinaryName =
      {
        "x86_64-linux" = "tailwindcss-linux-x64";
        "aarch64-linux" = "tailwindcss-linux-arm64";
        "x86_64-darwin" = "tailwindcss-macos-x64";
        "aarch64-darwin" = "tailwindcss-macos-arm64";
      }.${
        system
      } or "tailwindcss-linux-x64";
    tailwindBinaryHash =
      {
        "x86_64-linux" = "sha256-BwYpKTWpdzxsh54X0jYlMi5EkOfo96CtDmiPquTe+YE=";
        "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        "x86_64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        "aarch64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      }.${
        system
      } or "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    tailwindcss_4_src = pkgs.fetchurl {
      url = "https://github.com/tailwindlabs/tailwindcss/releases/download/v${tailwindVersion}/${tailwindBinaryName}";
      hash = tailwindBinaryHash;
    };
    # Patch the binary for NixOS (fix interpreter and library paths)
    tailwindcss_4 = pkgs.stdenv.mkDerivation {
      pname = "tailwindcss";
      version = tailwindVersion;
      src = tailwindcss_4_src;
      dontUnpack = true;
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/tailwindcss
        chmod +x $out/bin/tailwindcss
      '';
    };

    # Extract version from mix.exs
    version =
      ./mix.exs
      |> builtins.readFile
      |> builtins.replaceStrings ["\n"] [" "]
      |> builtins.match ''.*version: "([^"]+)".*''
      |> builtins.head;
  in {
    # Production package
    packages.default = beamPackages.mixRelease {
      inherit version;

      pname = "mydia";
      src = ../..;

      mixNixDeps = mixNixDeps;

      # Build-time dependencies
      nativeBuildInputs = [
        pkgs.nodejs
        pkgs.git
        pkgs.npmHooks.npmConfigHook
      ];

      # Runtime dependencies for NIFs
      # Use ffmpeg_6 for compatibility with membrane plugins
      buildInputs = [
        pkgs.sqlite
        pkgs.postgresql
        pkgs.ffmpeg_6-headless
      ];

      # Don't strip symbols (needed for Erlang NIFs)
      dontStrip = true;

      # Set HOME to a writable directory for elixir_make cache
      env = {
        HOME = "/tmp";
        DATABASE_TYPE = "postgres";
      };

      # Remove dev/test dependencies from the build
      removeCookie = false;

      # Pre-fetched npm dependencies
      inherit npmDeps;
      npmRoot = "assets";

      # Create missing deps symlinks for packages that don't have /src at root
      # but do have source in lib/erlang/lib/*/src (buildRebar3 packages)
      postConfigure = ''
        echo "=== postConfigure: Creating missing deps symlinks ==="

        # Create deps symlinks for packages linked in _build/prod/lib
        # but missing from deps/ (e.g., buildRebar3 packages like hackney, luerl)
        for lib_dir in _build/prod/lib/*; do
          dep_name=$(basename "$lib_dir")
          if [ ! -e "deps/$dep_name" ]; then
            # Follow the symlink to get the actual nix store path
            real_lib=$(readlink -f "$lib_dir")
            # Link to the full app directory (not just /src) so Mix can find .app files
            echo "  Creating symlink: deps/$dep_name -> $real_lib"
            ln -s "$real_lib" "deps/$dep_name"
          fi
        done

        echo "=== postConfigure: Done. deps/ count ==="
        ls deps/ | wc -l
      '';

      # Configure asset compilation
      preBuild = ''
        # Copy heroicons to deps (git dependency, not handled by mixNixDeps)
        mkdir -p deps/heroicons
        cp -r ${heroicons}/optimized deps/heroicons/

        # Install npm dependencies from cache (npmConfigHook sets up the cache)
        cd assets
        npm ci --ignore-scripts
        cd ..

        # Link platform-specific binaries for esbuild and tailwind
        # Use tailwindcss v4 binary (patched for NixOS)
        mkdir -p _build
        ln -sf ${pkgs.esbuild}/bin/esbuild _build/esbuild-${platformSuffix}
        ln -sf ${tailwindcss_4}/bin/tailwindcss _build/tailwind-${platformSuffix}

        # Build assets (use --no-deps-check to skip lock verification for Nix-managed deps)
        export MIX_ENV=prod
        mix do compile --no-deps-check, assets.deploy
      '';

      # Set environment for production
      MIX_ENV = "prod";

      # Post-install: wrap the release binary to include runtime deps
      postInstall = ''
        wrapProgram $out/bin/mydia \
          --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ffmpeg_6-headless pkgs.sqlite pkgs.postgresql]}
      '';
    };
  };
}
