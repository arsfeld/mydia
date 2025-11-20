defmodule MetadataRelay.MixProject do
  use Mix.Project

  def project do
    [
      app: :metadata_relay,
      version: "0.4.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MetadataRelay.Application, []}
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:plug, "~> 1.15"},
      {:req, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:redix, "~> 1.5"},
      {:ecto, "~> 3.11"},
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.17"},
      {:error_tracker, "~> 0.7"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      test: ["test"]
    ]
  end

  defp releases do
    [
      metadata_relay: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end
end
