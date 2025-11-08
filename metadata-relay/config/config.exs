import Config

# Configure the application
config :metadata_relay,
  # Default port for HTTP server
  port: 4000

# Configure the logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config
import_config "#{config_env()}.exs"
