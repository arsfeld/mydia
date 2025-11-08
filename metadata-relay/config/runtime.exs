import Config

# Runtime configuration loaded at application start
# This is where environment variables are read

if config_env() == :prod do
  # Port from environment variable
  port = System.get_env("PORT") || "4000"
  config :metadata_relay, port: String.to_integer(port)

  # API keys from environment
  tmdb_api_key = System.get_env("TMDB_API_KEY")
  tvdb_api_key = System.get_env("TVDB_API_KEY")

  config :metadata_relay,
    tmdb_api_key: tmdb_api_key,
    tvdb_api_key: tvdb_api_key
end
