{ lib, beamPackages, pkgs ? null, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    # NOTE: heroicons is a git dependency but NOT an Elixir package (app: false, compile: false)
    # It's handled separately during the build by fetching from GitHub
    # See flake.nix for how it's fetched and placed in deps/heroicons

    argon2_elixir = buildMix rec {
      name = "argon2_elixir";
      version = "4.1.3";

      src = fetchHex {
        pkg = "argon2_elixir";
        version = "${version}";
        sha256 = "7c295b8d8e0eaf6f43641698f962526cdf87c6feb7d14bd21e599271b510608c";
      };

      HOME = ".";
      beamDeps = [ comeonin elixir_make ];
    };

    bandit = buildMix rec {
      name = "bandit";
      version = "1.8.0";

      src = fetchHex {
        pkg = "bandit";
        version = "${version}";
        sha256 = "8458ff4eed20ff2a2ea69d4854883a077c33ea42b51f6811b044ceee0fa15422";
      };

      beamDeps = [ hpax plug telemetry thousand_island websock ];
    };

    bcrypt_elixir = buildMix rec {
      name = "bcrypt_elixir";
      version = "3.3.2";

      src = fetchHex {
        pkg = "bcrypt_elixir";
        version = "${version}";
        sha256 = "471be5151874ae7931911057d1467d908955f93554f7a6cd1b7d804cac8cef53";
      };

      HOME = ".";
      beamDeps = [ comeonin elixir_make ];
    };

    bimap = buildMix rec {
      name = "bimap";
      version = "1.3.0";

      src = fetchHex {
        pkg = "bimap";
        version = "${version}";
        sha256 = "bf5a2b078528465aa705f405a5c638becd63e41d280ada41e0f77e6d255a10b4";
      };

      beamDeps = [];
    };

    bunch = buildMix rec {
      name = "bunch";
      version = "1.6.1";

      src = fetchHex {
        pkg = "bunch";
        version = "${version}";
        sha256 = "286cc3add551628b30605efbe2fca4e38cc1bea89bcd0a1a7226920b3364fe4a";
      };

      beamDeps = [];
    };

    bunch_native = buildMix rec {
      name = "bunch_native";
      version = "0.5.0";

      src = fetchHex {
        pkg = "bunch_native";
        version = "${version}";
        sha256 = "24190c760e32b23b36edeb2dc4852515c7c5b3b8675b1a864e0715bdd1c8f80d";
      };

      beamDeps = [ bundlex ];
    };

    bundlex = buildMix rec {
      name = "bundlex";
      version = "1.5.4";

      src = fetchHex {
        pkg = "bundlex";
        version = "${version}";
        sha256 = "e745726606a560275182a8ac1c8ebd5e11a659bb7460d8abf30f397e59b4c5d2";
      };

      beamDeps = [ bunch elixir_uuid qex req zarex ];
    };

    bunt = buildMix rec {
      name = "bunt";
      version = "1.0.0";

      src = fetchHex {
        pkg = "bunt";
        version = "${version}";
        sha256 = "dc5f86aa08a5f6fa6b8096f0735c4e76d54ae5c9fa2c143e5a1fc7c1cd9bb6b5";
      };

      beamDeps = [];
    };

    bypass = buildMix rec {
      name = "bypass";
      version = "2.1.0";

      src = fetchHex {
        pkg = "bypass";
        version = "${version}";
        sha256 = "d9b5df8fa5b7a6efa08384e9bbecfe4ce61c77d28a4282f79e02f1ef78d96b80";
      };

      beamDeps = [ plug plug_cowboy ranch ];
    };

    cc_precompiler = buildMix rec {
      name = "cc_precompiler";
      version = "0.1.11";

      src = fetchHex {
        pkg = "cc_precompiler";
        version = "${version}";
        sha256 = "3427232caf0835f94680e5bcf082408a70b48ad68a5f5c0b02a3bea9f3a075b9";
      };

      HOME = ".";
      beamDeps = [ elixir_make ];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.15.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "b147ed22ce71d72eafdad94f055165c1c182f61a2ff49df28bcc71d1d5b94a60";
      };

      beamDeps = [];
    };

    coerce = buildMix rec {
      name = "coerce";
      version = "1.0.1";

      src = fetchHex {
        pkg = "coerce";
        version = "${version}";
        sha256 = "b44a691700f7a1a15b4b7e2ff1fa30bebd669929ac8aa43cffe9e2f8bf051cf1";
      };

      beamDeps = [];
    };

    combine = buildMix rec {
      name = "combine";
      version = "0.10.0";

      src = fetchHex {
        pkg = "combine";
        version = "${version}";
        sha256 = "1b1dbc1790073076580d0d1d64e42eae2366583e7aecd455d1215b0d16f2451b";
      };

      beamDeps = [];
    };

    comeonin = buildMix rec {
      name = "comeonin";
      version = "5.5.1";

      src = fetchHex {
        pkg = "comeonin";
        version = "${version}";
        sha256 = "65aac8f19938145377cee73973f192c5645873dcf550a8a6b18187d17c13ccdb";
      };

      beamDeps = [];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.14.2";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "569081da046e7b41b5df36aa359be71a0c8874e5b9cff6f747073fc57baf1ab9";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "cowboy_telemetry";
        version = "${version}";
        sha256 = "7d98bac1ee4565d31b62d59f8823dfd8356a169e7fcbb83831b8a5397404c9de";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.16.0";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "7f478d80d66b747344f0ea7708c187645cfcc08b11aa424632f78e25bf05db51";
      };

      beamDeps = [];
    };

    credo = buildMix rec {
      name = "credo";
      version = "1.7.13";

      src = fetchHex {
        pkg = "credo";
        version = "${version}";
        sha256 = "47641e6d2bbff1e241e87695b29f617f1a8f912adea34296fb10ecc3d7e9e84f";
      };

      beamDeps = [ bunt file_system jason ];
    };

    crontab = buildMix rec {
      name = "crontab";
      version = "1.2.0";

      src = fetchHex {
        pkg = "crontab";
        version = "${version}";
        sha256 = "ebd7ef4d831e1b20fa4700f0de0284a04cac4347e813337978e25b4cc5cc2207";
      };

      beamDeps = [ ecto ];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.8.1";

      src = fetchHex {
        pkg = "db_connection";
        version = "${version}";
        sha256 = "a61a3d489b239d76f326e03b98794fb8e45168396c925ef25feb405ed09da8fd";
      };

      beamDeps = [ telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.3.0";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "a4d66355cb29cb47c3cf30e71329e58361cfcb37c34235ef3bf1d7bf3773aeac";
      };

      beamDeps = [];
    };

    dialyxir = buildMix rec {
      name = "dialyxir";
      version = "1.4.6";

      src = fetchHex {
        pkg = "dialyxir";
        version = "${version}";
        sha256 = "8cf5615c5cd4c2da6c501faae642839c8405b49f8aa057ad4ae401cb808ef64d";
      };

      beamDeps = [ erlex ];
    };

    dns_cluster = buildMix rec {
      name = "dns_cluster";
      version = "0.2.0";

      src = fetchHex {
        pkg = "dns_cluster";
        version = "${version}";
        sha256 = "ba6f1893411c69c01b9e8e8f772062535a4cf70f3f35bcc964a324078d8c8240";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.13.4";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "5ad7d1505685dfa7aaf86b133d54f5ad6c42df0b4553741a1ff48796736e88b2";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.13.2";

      src = fetchHex {
        pkg = "ecto_sql";
        version = "${version}";
        sha256 = "539274ab0ecf1a0078a6a72ef3465629e4d6018a3028095dc90f60a19c371717";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    ecto_sqlite3 = buildMix rec {
      name = "ecto_sqlite3";
      version = "0.22.0";

      src = fetchHex {
        pkg = "ecto_sqlite3";
        version = "${version}";
        sha256 = "5af9e031bffcc5da0b7bca90c271a7b1e7c04a93fecf7f6cd35bc1b1921a64bd";
      };

      beamDeps = [ decimal ecto ecto_sql exqlite ];
    };

    elixir_make = buildMix rec {
      name = "elixir_make";
      version = "0.9.0";

      src = fetchHex {
        pkg = "elixir_make";
        version = "${version}";
        sha256 = "db23d4fd8b757462ad02f8aa73431a426fe6671c80b200d9710caf3d1dd0ffdb";
      };

      beamDeps = [];
    };

    elixir_uuid = buildMix rec {
      name = "elixir_uuid";
      version = "1.2.1";

      src = fetchHex {
        pkg = "elixir_uuid";
        version = "${version}";
        sha256 = "f7eba2ea6c3555cea09706492716b0d87397b88946e6380898c2889d68585752";
      };

      beamDeps = [];
    };

    erlex = buildMix rec {
      name = "erlex";
      version = "0.2.7";

      src = fetchHex {
        pkg = "erlex";
        version = "${version}";
        sha256 = "3ed95f79d1a844c3f6bf0cea61e0d5612a42ce56da9c03f01df538685365efb0";
      };

      beamDeps = [];
    };

    error_tracker = buildMix rec {
      name = "error_tracker";
      version = "0.7.0";

      src = fetchHex {
        pkg = "error_tracker";
        version = "${version}";
        sha256 = "47189e3b38d69e3caccc2fd6e3badf0dd2a37ebc8d720c8f6d526489dd758b05";
      };

      beamDeps = [ ecto ecto_sql ecto_sqlite3 jason phoenix_ecto phoenix_live_view plug postgrex ];
    };

    esbuild = buildMix rec {
      name = "esbuild";
      version = "0.10.0";

      src = fetchHex {
        pkg = "esbuild";
        version = "${version}";
        sha256 = "468489cda427b974a7cc9f03ace55368a83e1a7be12fba7e30969af78e5f8c70";
      };

      beamDeps = [ jason ];
    };

    ex_hls = buildMix rec {
      name = "ex_hls";
      version = "0.1.5";

      src = fetchHex {
        pkg = "ex_hls";
        version = "${version}";
        sha256 = "144b35920846db02af5212f0dcd2a11d87a2745f1d4307aa20a93c0323da8764";
      };

      beamDeps = [ ex_m3u8 membrane_h26x_plugin membrane_mp4_plugin mpeg_ts qex req ];
    };

    ex_m3u8 = buildMix rec {
      name = "ex_m3u8";
      version = "0.15.4";

      src = fetchHex {
        pkg = "ex_m3u8";
        version = "${version}";
        sha256 = "ec03aa516919e0c8ec202da55f609b763bd7960195a3388900090fcad270c873";
      };

      beamDeps = [ nimble_parsec typed_struct ];
    };

    ex_machina = buildMix rec {
      name = "ex_machina";
      version = "2.8.0";

      src = fetchHex {
        pkg = "ex_machina";
        version = "${version}";
        sha256 = "79fe1a9c64c0c1c1fab6c4fa5d871682cb90de5885320c187d117004627a7729";
      };

      beamDeps = [ ecto ecto_sql ];
    };

    expo = buildMix rec {
      name = "expo";
      version = "1.1.1";

      src = fetchHex {
        pkg = "expo";
        version = "${version}";
        sha256 = "5fb308b9cb359ae200b7e23d37c76978673aa1b06e2b3075d814ce12c5811640";
      };

      beamDeps = [];
    };

    exqlite = buildMix rec {
      name = "exqlite";
      version = "0.33.1";

      src = fetchHex {
        pkg = "exqlite";
        version = "${version}";
        sha256 = "b3db0c9ae6e5ee7cf84dd0a1b6dc7566b80912eb7746d45370f5666ed66700f9";
      };

      HOME = ".";
      beamDeps = [ cc_precompiler db_connection elixir_make ];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "1.1.1";

      src = fetchHex {
        pkg = "file_system";
        version = "${version}";
        sha256 = "7a15ff97dfe526aeefb090a7a9d3d03aa907e100e262a0f8f7746b78f8f87a5d";
      };

      beamDeps = [];
    };

    finch = buildMix rec {
      name = "finch";
      version = "0.20.0";

      src = fetchHex {
        pkg = "finch";
        version = "${version}";
        sha256 = "2658131a74d051aabfcba936093c903b8e89da9a1b63e430bee62045fa9b2ee2";
      };

      beamDeps = [ mime mint nimble_options nimble_pool telemetry ];
    };

    fine = buildMix rec {
      name = "fine";
      version = "0.1.4";

      src = fetchHex {
        pkg = "fine";
        version = "${version}";
        sha256 = "be3324cc454a42d80951cf6023b9954e9ff27c6daa255483b3e8d608670303f5";
      };

      beamDeps = [];
    };

    floki = buildMix rec {
      name = "floki";
      version = "0.38.0";

      src = fetchHex {
        pkg = "floki";
        version = "${version}";
        sha256 = "a5943ee91e93fb2d635b612caf5508e36d37548e84928463ef9dd986f0d1abd9";
      };

      beamDeps = [];
    };

    gettext = buildMix rec {
      name = "gettext";
      version = "0.26.2";

      src = fetchHex {
        pkg = "gettext";
        version = "${version}";
        sha256 = "aa978504bcf76511efdc22d580ba08e2279caab1066b76bb9aa81c4a1e0a32a5";
      };

      beamDeps = [ expo ];
    };

    guardian = buildMix rec {
      name = "guardian";
      version = "2.4.0";

      src = fetchHex {
        pkg = "guardian";
        version = "${version}";
        sha256 = "5c80103a9c538fbc2505bf08421a82e8f815deba9eaedb6e734c66443154c518";
      };

      beamDeps = [ jose plug ];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.25.0";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "7209bfd75fd1f42467211ff8f59ea74d6f2a9e81cbcee95a56711ee79fd6b1d4";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    heap = buildMix rec {
      name = "heap";
      version = "2.0.2";

      src = fetchHex {
        pkg = "heap";
        version = "${version}";
        sha256 = "ba9ea2fe99eb4bcbd9a8a28eaf71cbcac449ca1d8e71731596aace9028c9d429";
      };

      beamDeps = [];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "1.0.3";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "8eab6e1cfa8d5918c2ce4ba43588e894af35dbd8e91e6e55c817bca5847df34a";
      };

      beamDeps = [];
    };

    httpoison = buildMix rec {
      name = "httpoison";
      version = "2.3.0";

      src = fetchHex {
        pkg = "httpoison";
        version = "${version}";
        sha256 = "d388ee70be56d31a901e333dbcdab3682d356f651f93cf492ba9f06056436a2c";
      };

      beamDeps = [ hackney ];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.4";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "c5eb0cab91f094599f94d55bc63409236a8ec69a21a67814529e8d5f6cc90b3b";
      };

      beamDeps = [ decimal ];
    };

    jose = buildMix rec {
      name = "jose";
      version = "1.11.10";

      src = fetchHex {
        pkg = "jose";
        version = "${version}";
        sha256 = "0d6cd36ff8ba174db29148fc112b5842186b68a90ce9fc2b3ec3afe76593e614";
      };

      beamDeps = [];
    };

    lazy_html = buildMix rec {
      name = "lazy_html";
      version = "0.1.8";

      src = fetchHex {
        pkg = "lazy_html";
        version = "${version}";
        sha256 = "0d8167d930b704feb94b41414ca7f5779dff9bca7fcf619fcef18de138f08736";
      };

      # Set HOME for elixir_make cache directory
      HOME = ".";

      # Build tools needed to compile from source (when precompiled binary unavailable)
      nativeBuildInputs = lib.optionals (pkgs != null) [ pkgs.git pkgs.gnumake pkgs.gcc ];

      beamDeps = [ cc_precompiler elixir_make fine ];
    };

    logger_backends = buildMix rec {
      name = "logger_backends";
      version = "1.0.0";

      src = fetchHex {
        pkg = "logger_backends";
        version = "${version}";
        sha256 = "1faceb3e7ec3ef66a8f5746c5afd020e63996df6fd4eb8cdb789e5665ae6c9ce";
      };

      beamDeps = [];
    };

    luerl = buildRebar3 rec {
      name = "luerl";
      version = "1.5.0";

      src = fetchHex {
        pkg = "luerl";
        version = "${version}";
        sha256 = "76612d8b94a93f622f483e90a4d277a007590e12dceb9b35c8ff4be32d644484";
      };

      beamDeps = [];
    };

    membrane_aac_fdk_plugin = buildMix rec {
      name = "membrane_aac_fdk_plugin";
      version = "0.18.13";

      src = fetchHex {
        pkg = "membrane_aac_fdk_plugin";
        version = "${version}";
        sha256 = "4bc789c34a432099fe9c61c917c95ff66154d06ee7efd1785bc317a75b413247";
      };

      beamDeps = [ bunch bundlex membrane_aac_format membrane_common_c membrane_core membrane_precompiled_dependency_provider membrane_raw_audio_format unifex ];
    };

    membrane_aac_format = buildMix rec {
      name = "membrane_aac_format";
      version = "0.8.0";

      src = fetchHex {
        pkg = "membrane_aac_format";
        version = "${version}";
        sha256 = "a30176a94491033ed32be45e51d509fc70a5ee6e751f12fd6c0d60bd637013f6";
      };

      beamDeps = [ bimap ];
    };

    membrane_aac_plugin = buildMix rec {
      name = "membrane_aac_plugin";
      version = "0.19.1";

      src = fetchHex {
        pkg = "membrane_aac_plugin";
        version = "${version}";
        sha256 = "21158745f4d748eb15dd63e872d21a7deacb055294c0efb24b31960ad0400171";
      };

      beamDeps = [ bunch membrane_aac_format membrane_core ];
    };

    membrane_cmaf_format = buildMix rec {
      name = "membrane_cmaf_format";
      version = "0.7.1";

      src = fetchHex {
        pkg = "membrane_cmaf_format";
        version = "${version}";
        sha256 = "3c7b4ed2a986e27f6f336d2f19e9442cb31d93b3142fc024c019572faca54a73";
      };

      beamDeps = [];
    };

    membrane_common_c = buildMix rec {
      name = "membrane_common_c";
      version = "0.16.0";

      src = fetchHex {
        pkg = "membrane_common_c";
        version = "${version}";
        sha256 = "a3c7e91de1ce1f8b23b9823188a5d13654d317235ea0ca781c05353ed3be9b1c";
      };

      beamDeps = [ membrane_core shmex unifex ];
    };

    membrane_core = buildMix rec {
      name = "membrane_core";
      version = "1.2.4";

      src = fetchHex {
        pkg = "membrane_core";
        version = "${version}";
        sha256 = "ec7a77b7ab457267c0243338383365f6ef5ace2686ddc129939e502a58eba546";
      };

      beamDeps = [ bunch qex ratio telemetry ];
    };

    membrane_ffmpeg_swresample_plugin = buildMix rec {
      name = "membrane_ffmpeg_swresample_plugin";
      version = "0.20.3";

      src = fetchHex {
        pkg = "membrane_ffmpeg_swresample_plugin";
        version = "${version}";
        sha256 = "a1c1b14fbb5c3ebd26907942beaaeb4b7e6185c9cb668ef59d0819315fa3375a";
      };

      beamDeps = [ bunch bundlex membrane_common_c membrane_core membrane_precompiled_dependency_provider membrane_raw_audio_format mockery unifex ];
    };

    membrane_ffmpeg_swscale_plugin = buildMix rec {
      name = "membrane_ffmpeg_swscale_plugin";
      version = "0.16.3";

      src = fetchHex {
        pkg = "membrane_ffmpeg_swscale_plugin";
        version = "${version}";
        sha256 = "45384da60bb58ab2236bdd19119baf3df09e70906acf5801ac5dd1bd22921c4a";
      };

      beamDeps = [ bundlex membrane_common_c membrane_core membrane_precompiled_dependency_provider membrane_raw_video_format ];
    };

    membrane_file_plugin = buildMix rec {
      name = "membrane_file_plugin";
      version = "0.17.2";

      src = fetchHex {
        pkg = "membrane_file_plugin";
        version = "${version}";
        sha256 = "df50c6040004cd7b901cf057bd7e99c875bbbd6ae574efc93b2c753c96f43b9d";
      };

      beamDeps = [ logger_backends membrane_core ];
    };

    membrane_h264_ffmpeg_plugin = buildMix rec {
      name = "membrane_h264_ffmpeg_plugin";
      version = "0.32.6";

      src = fetchHex {
        pkg = "membrane_h264_ffmpeg_plugin";
        version = "${version}";
        sha256 = "1e333b0343f90d4ec58acc44a7edf7f6a8c5a73eb70407e42b201d664357b290";
      };

      beamDeps = [ bunch bundlex membrane_common_c membrane_core membrane_h264_format membrane_precompiled_dependency_provider membrane_raw_video_format unifex ];
    };

    membrane_h264_format = buildMix rec {
      name = "membrane_h264_format";
      version = "0.6.1";

      src = fetchHex {
        pkg = "membrane_h264_format";
        version = "${version}";
        sha256 = "4b79be56465a876d2eac2c3af99e115374bbdc03eb1dea4f696ee9a8033cd4b0";
      };

      beamDeps = [];
    };

    membrane_h265_ffmpeg_plugin = buildMix rec {
      name = "membrane_h265_ffmpeg_plugin";
      version = "0.4.3";

      src = fetchHex {
        pkg = "membrane_h265_ffmpeg_plugin";
        version = "${version}";
        sha256 = "24dc587731e7b5bc4b35da1b85e849476eff6a9a7b934ff0b2b5efae037b8589";
      };

      beamDeps = [ bunch bundlex membrane_core membrane_h265_format membrane_precompiled_dependency_provider membrane_raw_video_format unifex ];
    };

    membrane_h265_format = buildMix rec {
      name = "membrane_h265_format";
      version = "0.2.0";

      src = fetchHex {
        pkg = "membrane_h265_format";
        version = "${version}";
        sha256 = "6df418bdf242c0d9f7dbf2e5aea4c2d182e34ac9ad5a8b8cef2610c290002e83";
      };

      beamDeps = [];
    };

    membrane_h26x_plugin = buildMix rec {
      name = "membrane_h26x_plugin";
      version = "0.10.5";

      src = fetchHex {
        pkg = "membrane_h26x_plugin";
        version = "${version}";
        sha256 = "dd0287a6b6223e47bba30a8952d6ec53db35f6a3e33203b7ad786e995711f098";
      };

      beamDeps = [ bunch membrane_core membrane_h264_format membrane_h265_format ];
    };

    membrane_http_adaptive_stream_plugin = buildMix rec {
      name = "membrane_http_adaptive_stream_plugin";
      version = "0.20.2";

      src = fetchHex {
        pkg = "membrane_http_adaptive_stream_plugin";
        version = "${version}";
        sha256 = "0c8aba8640375f1f455359f4fdeb0886bf1abad0f348b27f67afccd49abb4e00";
      };

      beamDeps = [ bunch ex_hls membrane_aac_plugin membrane_core membrane_h26x_plugin membrane_mp4_plugin membrane_tee_plugin qex stream_split ];
    };

    membrane_matroska_format = buildMix rec {
      name = "membrane_matroska_format";
      version = "0.1.0";

      src = fetchHex {
        pkg = "membrane_matroska_format";
        version = "${version}";
        sha256 = "8bf180165ea9bb4094673818df5989fe6bd44b752a86dc071daafe611af1f3cc";
      };

      beamDeps = [];
    };

    membrane_matroska_plugin = buildMix rec {
      name = "membrane_matroska_plugin";
      version = "0.6.1";

      src = fetchHex {
        pkg = "membrane_matroska_plugin";
        version = "${version}";
        sha256 = "9db2a7ea8056c4c7ac6b0e61dc4913f556962e8489691ed971e1bfd6d2cd3cd5";
      };

      beamDeps = [ bimap membrane_common_c membrane_core membrane_file_plugin membrane_h264_format membrane_matroska_format membrane_opus_format membrane_vp8_format membrane_vp9_format qex ];
    };

    membrane_mp4_format = buildMix rec {
      name = "membrane_mp4_format";
      version = "0.8.0";

      src = fetchHex {
        pkg = "membrane_mp4_format";
        version = "${version}";
        sha256 = "148dea678a1f82ccfd44dbde6f936d2f21255f496cb45a22cc6eec427f025522";
      };

      beamDeps = [];
    };

    membrane_mp4_plugin = buildMix rec {
      name = "membrane_mp4_plugin";
      version = "0.36.0";

      src = fetchHex {
        pkg = "membrane_mp4_plugin";
        version = "${version}";
        sha256 = "84f55a42c69cb557b73d6272f958812f607abaaa6a3473f301d22393f2a62808";
      };

      beamDeps = [ bunch membrane_aac_format membrane_cmaf_format membrane_core membrane_file_plugin membrane_h264_format membrane_h265_format membrane_mp4_format membrane_opus_format membrane_timestamp_queue ];
    };

    membrane_opus_format = buildMix rec {
      name = "membrane_opus_format";
      version = "0.3.0";

      src = fetchHex {
        pkg = "membrane_opus_format";
        version = "${version}";
        sha256 = "8fc89c97be50de23ded15f2050fe603dcce732566fe6fdd15a2de01cb6b81afe";
      };

      beamDeps = [];
    };

    membrane_precompiled_dependency_provider = buildMix rec {
      name = "membrane_precompiled_dependency_provider";
      version = "0.2.2";

      src = fetchHex {
        pkg = "membrane_precompiled_dependency_provider";
        version = "${version}";
        sha256 = "60296232d613856d22494303b64487bfa141666544f2e83a97f1d2dd28c34453";
      };

      beamDeps = [ bundlex ];
    };

    membrane_raw_audio_format = buildMix rec {
      name = "membrane_raw_audio_format";
      version = "0.12.0";

      src = fetchHex {
        pkg = "membrane_raw_audio_format";
        version = "${version}";
        sha256 = "6e6c98e3622a2b9df19eab50ba65d7eb45949b1ba306fa8423df6cdb12fd0b44";
      };

      beamDeps = [ bimap bunch membrane_core ];
    };

    membrane_raw_video_format = buildMix rec {
      name = "membrane_raw_video_format";
      version = "0.4.1";

      src = fetchHex {
        pkg = "membrane_raw_video_format";
        version = "${version}";
        sha256 = "9920b7d445b5357608a364fec5685acdfce85334c647f745045237a0d296c442";
      };

      beamDeps = [];
    };

    membrane_realtimer_plugin = buildMix rec {
      name = "membrane_realtimer_plugin";
      version = "0.10.1";

      src = fetchHex {
        pkg = "membrane_realtimer_plugin";
        version = "${version}";
        sha256 = "e961cf8aab3857f686eba9a61aaa91a818fe70b1e1282d09f4d6db06acb9dd67";
      };

      beamDeps = [ membrane_core ];
    };

    membrane_tee_plugin = buildMix rec {
      name = "membrane_tee_plugin";
      version = "0.12.0";

      src = fetchHex {
        pkg = "membrane_tee_plugin";
        version = "${version}";
        sha256 = "0d61c9ed5e68e5a75d54200e1c6df5739c0bcb52fee0974183ad72446a179887";
      };

      beamDeps = [ bunch membrane_core ];
    };

    membrane_timestamp_queue = buildMix rec {
      name = "membrane_timestamp_queue";
      version = "0.2.2";

      src = fetchHex {
        pkg = "membrane_timestamp_queue";
        version = "${version}";
        sha256 = "7c830e760baaced0988421671cd2c83c7cda8d1bd2b61fd05332711675d1204f";
      };

      beamDeps = [ heap membrane_core ];
    };

    membrane_vp8_format = buildMix rec {
      name = "membrane_vp8_format";
      version = "0.5.0";

      src = fetchHex {
        pkg = "membrane_vp8_format";
        version = "${version}";
        sha256 = "d29e0dae4bebc6838e82e031c181fe626d168c687e4bc617c1d0772bdeed19d5";
      };

      beamDeps = [];
    };

    membrane_vp9_format = buildMix rec {
      name = "membrane_vp9_format";
      version = "0.5.0";

      src = fetchHex {
        pkg = "membrane_vp9_format";
        version = "${version}";
        sha256 = "68752d8cbe7270ec222fc84a7d1553499f0d8ff86ef9d9e89f8955d49e20278e";
      };

      beamDeps = [];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.7";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "6171188e399ee16023ffc5b76ce445eb6d9672e2e241d2df6050f3c771e80ccd";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.4.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "13af15f9f68c65884ecca3a3891d50a7b57d82152792f3e19d88650aa126b144";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.7.1";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "fceba0a4d0f24301ddee3024ae116df1c3f4bb7a563a731f45fdfeb9d39a231b";
      };

      beamDeps = [ hpax ];
    };

    mockery = buildMix rec {
      name = "mockery";
      version = "2.5.0";

      src = fetchHex {
        pkg = "mockery";
        version = "${version}";
        sha256 = "52492b2eba61055df1c626e894663b624b5e6fdfaaaba1d9a8596236fbf4da69";
      };

      beamDeps = [];
    };

    mpeg_ts = buildMix rec {
      name = "mpeg_ts";
      version = "2.0.2";

      src = fetchHex {
        pkg = "mpeg_ts";
        version = "${version}";
        sha256 = "5b7f1245a945de647c29abc9453e3d9d7eca1b0001d3d582f4feb11fc09b2792";
      };

      beamDeps = [];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.1.1";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "821b2470ca9442c4b6984882fe9bb0389371b8ddec4d45a9504f00a66f650b44";
      };

      beamDeps = [];
    };

    nimble_parsec = buildMix rec {
      name = "nimble_parsec";
      version = "1.4.2";

      src = fetchHex {
        pkg = "nimble_parsec";
        version = "${version}";
        sha256 = "4b21398942dda052b403bbe1da991ccd03a053668d147d53fb8c4e0efe09c973";
      };

      beamDeps = [];
    };

    nimble_pool = buildMix rec {
      name = "nimble_pool";
      version = "1.1.0";

      src = fetchHex {
        pkg = "nimble_pool";
        version = "${version}";
        sha256 = "af2e4e6b34197db81f7aad230c1118eac993acc0dae6bc83bac0126d4ae0813a";
      };

      beamDeps = [];
    };

    numbers = buildMix rec {
      name = "numbers";
      version = "5.2.4";

      src = fetchHex {
        pkg = "numbers";
        version = "${version}";
        sha256 = "eeccf5c61d5f4922198395bf87a465b6f980b8b862dd22d28198c5e6fab38582";
      };

      beamDeps = [ coerce decimal ];
    };

    oban = buildMix rec {
      name = "oban";
      version = "2.20.1";

      src = fetchHex {
        pkg = "oban";
        version = "${version}";
        sha256 = "17a45277dbeb41a455040b41dd8c467163fad685d1366f2f59207def3bcdd1d8";
      };

      beamDeps = [ ecto_sql ecto_sqlite3 jason postgrex telemetry ];
    };

    oidcc = buildMix rec {
      name = "oidcc";
      version = "3.6.0";

      src = fetchHex {
        pkg = "oidcc";
        version = "${version}";
        sha256 = "99b26b1db95d617150416b18a7a84bb09525007fdbbcf963a60edb6156c6a1ce";
      };

      beamDeps = [ jose telemetry telemetry_registry ];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    phoenix = buildMix rec {
      name = "phoenix";
      version = "1.8.1";

      src = fetchHex {
        pkg = "phoenix";
        version = "${version}";
        sha256 = "84d77d2b2e77c3c7e7527099bd01ef5c8560cd149c036d6b3a40745f11cd2fb2";
      };

      beamDeps = [ bandit jason phoenix_pubsub phoenix_template plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_ecto = buildMix rec {
      name = "phoenix_ecto";
      version = "4.6.5";

      src = fetchHex {
        pkg = "phoenix_ecto";
        version = "${version}";
        sha256 = "26ec3208eef407f31b748cadd044045c6fd485fbff168e35963d2f9dfff28d4b";
      };

      beamDeps = [ ecto phoenix_html plug postgrex ];
    };

    phoenix_html = buildMix rec {
      name = "phoenix_html";
      version = "4.3.0";

      src = fetchHex {
        pkg = "phoenix_html";
        version = "${version}";
        sha256 = "3eaa290a78bab0f075f791a46a981bbe769d94bc776869f4f3063a14f30497ad";
      };

      beamDeps = [];
    };

    phoenix_live_dashboard = buildMix rec {
      name = "phoenix_live_dashboard";
      version = "0.8.7";

      src = fetchHex {
        pkg = "phoenix_live_dashboard";
        version = "${version}";
        sha256 = "3a8625cab39ec261d48a13b7468dc619c0ede099601b084e343968309bd4d7d7";
      };

      beamDeps = [ ecto mime phoenix_live_view telemetry_metrics ];
    };

    phoenix_live_reload = buildMix rec {
      name = "phoenix_live_reload";
      version = "1.6.1";

      src = fetchHex {
        pkg = "phoenix_live_reload";
        version = "${version}";
        sha256 = "74273843d5a6e4fef0bbc17599f33e3ec63f08e69215623a0cd91eea4288e5a0";
      };

      beamDeps = [ file_system phoenix ];
    };

    phoenix_live_view = buildMix rec {
      name = "phoenix_live_view";
      version = "1.1.16";

      src = fetchHex {
        pkg = "phoenix_live_view";
        version = "${version}";
        sha256 = "f2a0093895b8ef4880af76d41de4a9cf7cff6c66ad130e15a70bdabc4d279feb";
      };

      beamDeps = [ jason lazy_html phoenix phoenix_html phoenix_template plug telemetry ];
    };

    phoenix_pubsub = buildMix rec {
      name = "phoenix_pubsub";
      version = "2.2.0";

      src = fetchHex {
        pkg = "phoenix_pubsub";
        version = "${version}";
        sha256 = "adc313a5bf7136039f63cfd9668fde73bba0765e0614cba80c06ac9460ff3e96";
      };

      beamDeps = [];
    };

    phoenix_template = buildMix rec {
      name = "phoenix_template";
      version = "1.0.4";

      src = fetchHex {
        pkg = "phoenix_template";
        version = "${version}";
        sha256 = "2c0c81f0e5c6753faf5cca2f229c9709919aba34fab866d3bc05060c9c444206";
      };

      beamDeps = [ phoenix_html ];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.18.1";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "57a57db70df2b422b564437d2d33cf8d33cd16339c1edb190cd11b1a3a546cc2";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.7.4";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "9b85632bd7012615bae0a5d70084deb1b25d2bcbb32cab82d1e9a1e023168aa3";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.1.1";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "6470bce6ffe41c8bd497612ffde1a7e4af67f36a15eea5f921af71cf3e11247c";
      };

      beamDeps = [];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.21.1";

      src = fetchHex {
        pkg = "postgrex";
        version = "${version}";
        sha256 = "27d8d21c103c3cc68851b533ff99eef353e6a0ff98dc444ea751de43eb48bdac";
      };

      beamDeps = [ db_connection decimal jason ];
    };

    qex = buildMix rec {
      name = "qex";
      version = "0.5.1";

      src = fetchHex {
        pkg = "qex";
        version = "${version}";
        sha256 = "935a39fdaf2445834b95951456559e9dc2063d0a055742c558a99987b38d6bab";
      };

      beamDeps = [];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.1";

      src = fetchHex {
        pkg = "ranch";
        version = "${version}";
        sha256 = "aed58910f4e21deea992a67bf51632b6d60114895eb03bb392bb733064594dd0";
      };

      beamDeps = [];
    };

    ratio = buildMix rec {
      name = "ratio";
      version = "4.0.1";

      src = fetchHex {
        pkg = "ratio";
        version = "${version}";
        sha256 = "c60cbb3ccdff9ffa56e7d6d1654b5c70d9f90f4d753ab3a43a6bf40855b881ce";
      };

      beamDeps = [ decimal numbers ];
    };

    req = buildMix rec {
      name = "req";
      version = "0.5.15";

      src = fetchHex {
        pkg = "req";
        version = "${version}";
        sha256 = "a6513a35fad65467893ced9785457e91693352c70b58bbc045b47e5eb2ef0c53";
      };

      beamDeps = [ finch jason mime plug ];
    };

    shmex = buildMix rec {
      name = "shmex";
      version = "0.5.1";

      src = fetchHex {
        pkg = "shmex";
        version = "${version}";
        sha256 = "c29f8286891252f64c4e1dac40b217d960f7d58def597c4e606ff8fbe71ceb80";
      };

      beamDeps = [ bunch_native bundlex ];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    stream_split = buildMix rec {
      name = "stream_split";
      version = "0.1.7";

      src = fetchHex {
        pkg = "stream_split";
        version = "${version}";
        sha256 = "1dc072ff507a64404a0ad7af90df97096183fee8eeac7b300320cea7c4679147";
      };

      beamDeps = [];
    };

    sweet_xml = buildMix rec {
      name = "sweet_xml";
      version = "0.7.5";

      src = fetchHex {
        pkg = "sweet_xml";
        version = "${version}";
        sha256 = "193b28a9b12891cae351d81a0cead165ffe67df1b73fe5866d10629f4faefb12";
      };

      beamDeps = [];
    };

    tailwind = buildMix rec {
      name = "tailwind";
      version = "0.4.1";

      src = fetchHex {
        pkg = "tailwind";
        version = "${version}";
        sha256 = "6249d4f9819052911120dbdbe9e532e6bd64ea23476056adb7f730aa25c220d1";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.3.0";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "7015fc8919dbe63764f4b4b87a95b7c0996bd539e0d499be6ec9d7f3875b79e6";
      };

      beamDeps = [];
    };

    telemetry_metrics = buildMix rec {
      name = "telemetry_metrics";
      version = "1.1.0";

      src = fetchHex {
        pkg = "telemetry_metrics";
        version = "${version}";
        sha256 = "e7b79e8ddfde70adb6db8a6623d1778ec66401f366e9a8f5dd0955c56bc8ce67";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.3.0";

      src = fetchHex {
        pkg = "telemetry_poller";
        version = "${version}";
        sha256 = "51f18bed7128544a50f75897db9974436ea9bfba560420b646af27a9a9b35211";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_registry = buildMix rec {
      name = "telemetry_registry";
      version = "0.3.2";

      src = fetchHex {
        pkg = "telemetry_registry";
        version = "${version}";
        sha256 = "e7ed191eb1d115a3034af8e1e35e4e63d5348851d556646d46ca3d1b4e16bab9";
      };

      beamDeps = [ telemetry ];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.15.3";

      src = fetchHex {
        pkg = "tesla";
        version = "${version}";
        sha256 = "98bb3d4558abc67b92fb7be4cd31bb57ca8d80792de26870d362974b58caeda7";
      };

      beamDeps = [ finch hackney jason mime mint telemetry ];
    };

    thousand_island = buildMix rec {
      name = "thousand_island";
      version = "1.4.2";

      src = fetchHex {
        pkg = "thousand_island";
        version = "${version}";
        sha256 = "1c7637f16558fc1c35746d5ee0e83b18b8e59e18d28affd1f2fa1645f8bc7473";
      };

      beamDeps = [ telemetry ];
    };

    timex = buildMix rec {
      name = "timex";
      version = "3.7.13";

      src = fetchHex {
        pkg = "timex";
        version = "${version}";
        sha256 = "09588e0522669328e973b8b4fd8741246321b3f0d32735b589f78b136e6d4c54";
      };

      beamDeps = [ combine gettext tzdata ];
    };

    typed_struct = buildMix rec {
      name = "typed_struct";
      version = "0.3.0";

      src = fetchHex {
        pkg = "typed_struct";
        version = "${version}";
        sha256 = "c50bd5c3a61fe4e198a8504f939be3d3c85903b382bde4865579bc23111d1b6d";
      };

      beamDeps = [];
    };

    tzdata = buildMix rec {
      name = "tzdata";
      version = "1.1.3";

      src = fetchHex {
        pkg = "tzdata";
        version = "${version}";
        sha256 = "d4ca85575a064d29d4e94253ee95912edfb165938743dbf002acdf0dcecb0c28";
      };

      beamDeps = [ hackney ];
    };

    ueberauth = buildMix rec {
      name = "ueberauth";
      version = "0.10.8";

      src = fetchHex {
        pkg = "ueberauth";
        version = "${version}";
        sha256 = "f2d3172e52821375bccb8460e5fa5cb91cfd60b19b636b6e57e9759b6f8c10c1";
      };

      beamDeps = [ plug ];
    };

    ueberauth_oidcc = buildMix rec {
      name = "ueberauth_oidcc";
      version = "0.4.2";

      src = fetchHex {
        pkg = "ueberauth_oidcc";
        version = "${version}";
        sha256 = "b9ea3c981464a5052e4f4fbf0a3c716e124da056aca30b9754654c5c6f90f8c2";
      };

      beamDeps = [ oidcc plug ueberauth ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.1";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "b3a917854ce3ae233619744ad1e0102e05673136776fb2fa76234f3e03b23642";
      };

      beamDeps = [];
    };

    unifex = buildMix rec {
      name = "unifex";
      version = "1.2.1";

      src = fetchHex {
        pkg = "unifex";
        version = "${version}";
        sha256 = "8c9d2e3c48df031e9995dd16865bab3df402c0295ba3a31f38274bb5314c7d37";
      };

      beamDeps = [ bunch bundlex shmex ];
    };

    wallaby = buildMix rec {
      name = "wallaby";
      version = "0.30.11";

      src = fetchHex {
        pkg = "wallaby";
        version = "${version}";
        sha256 = "407b50972e3827ce77e3b8292c36dcbd6b21b6837cc4f12ee8767e92a72610ac";
      };

      beamDeps = [ ecto_sql httpoison jason phoenix_ecto web_driver_client ];
    };

    web_driver_client = buildMix rec {
      name = "web_driver_client";
      version = "0.2.0";

      src = fetchHex {
        pkg = "web_driver_client";
        version = "${version}";
        sha256 = "83cc6092bc3e74926d1c8455f0ce927d5d1d36707b74d9a65e38c084aab0350f";
      };

      beamDeps = [ hackney jason tesla ];
    };

    websock = buildMix rec {
      name = "websock";
      version = "0.5.3";

      src = fetchHex {
        pkg = "websock";
        version = "${version}";
        sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
      };

      beamDeps = [];
    };

    websock_adapter = buildMix rec {
      name = "websock_adapter";
      version = "0.5.8";

      src = fetchHex {
        pkg = "websock_adapter";
        version = "${version}";
        sha256 = "315b9a1865552212b5f35140ad194e67ce31af45bcee443d4ecb96b5fd3f3782";
      };

      beamDeps = [ bandit plug plug_cowboy websock ];
    };

    yamerl = buildRebar3 rec {
      name = "yamerl";
      version = "0.10.0";

      src = fetchHex {
        pkg = "yamerl";
        version = "${version}";
        sha256 = "346adb2963f1051dc837a2364e4acf6eb7d80097c0f53cbdc3046ec8ec4b4e6e";
      };

      beamDeps = [];
    };

    yaml_elixir = buildMix rec {
      name = "yaml_elixir";
      version = "2.12.0";

      src = fetchHex {
        pkg = "yaml_elixir";
        version = "${version}";
        sha256 = "ca6bacae7bac917a7155dca0ab6149088aa7bc800c94d0fe18c5238f53b313c6";
      };

      beamDeps = [ yamerl ];
    };

    ymlr = buildMix rec {
      name = "ymlr";
      version = "5.1.4";

      src = fetchHex {
        pkg = "ymlr";
        version = "${version}";
        sha256 = "75f16cf0709fbd911b30311a0359a7aa4b5476346c01882addefd5f2b1cfaa51";
      };

      beamDeps = [];
    };

    zarex = buildMix rec {
      name = "zarex";
      version = "1.0.6";

      src = fetchHex {
        pkg = "zarex";
        version = "${version}";
        sha256 = "b628a9b0bc312f278af2c288078c31fd4757224b82d768e91bcf3bedbe3a50e7";
      };

      beamDeps = [];
    };
  };
in self

