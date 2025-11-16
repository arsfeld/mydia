# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mydia,
  ecto_repos: [Mydia.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :mydia, MydiaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MydiaWeb.ErrorHTML, json: MydiaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mydia.PubSub,
  live_view: [signing_salt: "fUhVwVhL"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  mydia: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  mydia: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :request_id,
    # Media and library metadata
    :media_item_id,
    :media_item_count,
    :media_type,
    :media_file_id,
    :library_path_id,
    :library_path,
    :library_type,
    :required_library_types,
    # Episode and season metadata
    :episode_id,
    :episode_number,
    :episode_count,
    :episode,
    :episodes,
    :parsed_episodes,
    :episode_season,
    :season_number,
    :season,
    :parsed_season,
    :season_pack_season,
    :current_episode,
    :current_season,
    :new_episode,
    :old_episode,
    :total_episodes,
    :missing_count,
    # Title and identification metadata
    :title,
    :series_title,
    :result_title,
    :local_title,
    :tmdb_id,
    :provider_id,
    :provider_type,
    # File and path metadata
    :path,
    :path1,
    :path2,
    :file,
    :file_id,
    :file_path,
    :file_paths,
    :filename,
    :new_path,
    :old_path,
    :dest,
    :source,
    :original,
    :directory,
    :recursive,
    :sample_paths,
    # Download and torrent metadata
    :download_id,
    :client,
    :client_id,
    :save_path,
    :torrent_id,
    :torrent_name,
    :confidence,
    # Counts and statistics
    :count,
    :file_count,
    :total_files,
    :files_found,
    :files_scanned,
    :new_files,
    :modified_files,
    :deleted_count,
    :completed_count,
    :failed_count,
    :items_processed,
    :shows_processed,
    :orphaned_files_fixed,
    :tv_orphans_fixed,
    # Search and matching metadata
    :query,
    :score,
    :match_score,
    :best_score,
    :breakdown,
    :total_results,
    :no_results,
    :searches_performed,
    :searches_for_show,
    :searches_this_season,
    :searches_so_far,
    :search_count,
    :max_searches_per_run,
    :max_searches_per_season,
    # Quality and technical metadata
    :resolution,
    :codec,
    :audio,
    :device,
    :device1,
    :device2,
    # Status and results
    :reason,
    :error,
    :errors,
    :success,
    :successful,
    :failed,
    :skipped,
    :found,
    :total,
    :exit_code,
    :output,
    # Time and progress metadata
    :duration_ms,
    :retention_days,
    :completed_at,
    :air_date,
    :position,
    :percentage,
    # Job and configuration metadata
    :args,
    :mode,
    :type,
    :id,
    :key,
    :value,
    :metadata,
    :delete_files,
    :year,
    :show,
    # Additional metadata keys
    :from,
    :to,
    :deleted_files,
    :episodes_count,
    :episodes_skipped,
    :missing_episodes,
    :missing_percentage,
    :parsed_episode,
    :parsed_info,
    :has_parsed_info,
    :has_media_file_id,
    :matches,
    :match_result_keys,
    :associations_updated,
    :available_libraries,
    :current_search_count,
    :searches_remaining,
    :seasons_remaining,
    :shows_remaining,
    :shows_skipped,
    :show_searches_used,
    :max_searches_per_show,
    :invalid_paths_removed,
    :untracked_matched,
    :total_count,
    :media_item,
    :type_mismatches_detected,
    :movies_in_series_libs,
    :tv_in_movies_libs
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Guardian for JWT authentication
config :mydia, Mydia.Auth.Guardian,
  issuer: "mydia",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true,
  secret_key: "REPLACE_IN_RUNTIME_CONFIG"

# Configure Oban for background job processing
# Using Lite engine with polling for SQLite compatibility
config :mydia, Oban,
  repo: Mydia.Repo,
  engine: Oban.Engines.Lite,
  queues: [
    critical: 10,
    default: 5,
    media: 3,
    search: 2,
    notifications: 1,
    maintenance: 1
  ],
  plugins: [
    # Keep completed jobs for 7 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    # Scheduled jobs
    {Oban.Plugins.Cron,
     crontab: [
       # Scan library every hour
       {"0 * * * *", Mydia.Jobs.LibraryScanner},
       # Monitor downloads every 2 minutes
       {"*/2 * * * *", Mydia.Jobs.DownloadMonitor},
       # Search for monitored movies every 30 minutes
       {"*/30 * * * *", Mydia.Jobs.MovieSearch, args: %{"mode" => "all_monitored"}},
       # Search for monitored TV shows every 15 minutes
       {"*/15 * * * *", Mydia.Jobs.TVShowSearch, args: %{"mode" => "all_monitored"}},
       # Clean up old events every Sunday at 2 AM
       {"0 2 * * 0", Mydia.Jobs.EventCleanup},
       # Sync Cardigann definitions daily at 3 AM
       {"0 3 * * *", Mydia.Jobs.DefinitionSync}
     ]}
  ]

# Event retention configuration
# Events older than this will be automatically deleted
config :mydia, :event_retention_days, 90

# HLS Streaming configuration
# Backend can be :ffmpeg or :membrane
# :ffmpeg is the default as it supports more codecs and is more reliable
# :membrane is experimental and has limited codec support but provides more granular control
config :mydia, :streaming,
  hls_backend: :ffmpeg,
  # Session timeout (30 minutes of inactivity)
  session_timeout: :timer.minutes(30),
  # Temp directory for HLS segments
  temp_base_dir: "/tmp/mydia-hls",
  # Transcoding policy: :copy_when_compatible or :always
  # :copy_when_compatible - Use stream copy for compatible codecs (H.264/AAC) - 10-100x faster, zero quality loss
  # :always - Always re-encode (original behavior, slower but ensures consistent output)
  transcode_policy: :copy_when_compatible

# Episode monitor search limits
# Prevents excessive API usage that exhausts indexer quotas
config :mydia, :episode_monitor,
  # Max total searches across all shows per execution (prevents quota exhaustion)
  max_searches_per_run: 50,
  # Max searches for a single show per execution (ensures fair distribution)
  max_searches_per_show: 10,
  # Max searches for a single season per execution (limits season pack fallback impact)
  max_searches_per_season: 5,
  # Monitor special episodes (season 0) - default false due to low success rate (<5%)
  # Special episodes are rarely available on indexers and waste API quota
  # Set to true to search for specials, or search manually via UI
  monitor_special_episodes: false,
  # Delay between searches in milliseconds (prevents rapid-fire API calls)
  # Set to 0 to disable delays, 250-500ms recommended for respectful API usage
  search_delay_ms: 250

# Feature flags
config :mydia, :features,
  # Enable/disable media playback feature (Play Movie, Play Episode buttons)
  # Set to false to hide playback controls from the UI
  # Can be overridden via ENABLE_PLAYBACK environment variable
  playback_enabled: false,
  # Enable/disable Cardigann native indexer support
  # When enabled, provides access to hundreds of torrent indexers without external Prowlarr/Jackett
  # Set to false to disable Cardigann indexers (default)
  # Can be overridden via ENABLE_CARDIGANN environment variable
  cardigann_enabled: false

# Configure Ueberauth with empty providers by default
# This is overridden in dev.exs if OIDC is configured
config :ueberauth, Ueberauth, providers: []

# Configure ErrorTracker for local crash reporting
config :error_tracker,
  repo: Mydia.Repo,
  otp_app: :mydia,
  # Store crashes for 30 days
  prune_after: 30 * 24 * 60 * 60,
  # Enable in production and development, but not test
  enabled: config_env() != :test

# Configure Logger backends for crash reporting
# The crash reporter backend will automatically capture errors when enabled
config :logger,
  backends: [:console, Mydia.CrashReporter.LoggerBackend]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
