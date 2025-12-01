defmodule Mydia.Jobs.Broadcaster do
  @moduledoc """
  Broadcasts Oban job status changes to PubSub for real-time UI updates.

  This module attaches to Oban telemetry events and broadcasts to a PubSub topic
  so that LiveViews can subscribe and update their UI when jobs start/complete.
  """

  require Logger

  @pubsub Mydia.PubSub
  @topic "jobs:status"

  @doc """
  Returns the PubSub topic for job status updates.
  """
  def topic, do: @topic

  @doc """
  Subscribes the current process to job status updates.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  @doc """
  Attaches telemetry handlers for Oban job events.
  Should be called once at application startup.
  """
  def attach do
    :telemetry.attach_many(
      "mydia-jobs-broadcaster",
      [
        [:oban, :job, :start],
        [:oban, :job, :stop],
        [:oban, :job, :exception]
      ],
      &handle_event/4,
      nil
    )
  end

  @doc """
  Detaches the telemetry handlers.
  """
  def detach do
    :telemetry.detach("mydia-jobs-broadcaster")
  end

  @doc """
  Broadcasts the current job status to all subscribers.
  Called after job events to notify listeners.
  """
  def broadcast_status do
    executing_jobs = Mydia.Jobs.list_executing_jobs()
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:jobs_status_changed, executing_jobs})
  end

  # Telemetry event handlers

  def handle_event([:oban, :job, :start], _measurements, _metadata, _config) do
    broadcast_status()
  end

  def handle_event([:oban, :job, :stop], _measurements, _metadata, _config) do
    broadcast_status()
  end

  def handle_event([:oban, :job, :exception], _measurements, _metadata, _config) do
    broadcast_status()
  end
end
