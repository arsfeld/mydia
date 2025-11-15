defmodule Mydia.CrashReporter.Queue do
  @moduledoc """
  Local queue for crash reports.

  Manages a persistent queue of crash reports that need to be sent to the metadata relay.
  Handles retry logic for failed sends and ensures reports are not lost if the metadata
  relay is temporarily unavailable.

  ## Features
  - In-memory queue with ETS persistence
  - Automatic retry with exponential backoff
  - Configurable max retries
  - Background worker for processing queue
  """

  use GenServer
  require Logger

  alias Mydia.CrashReporter.Sender

  @table_name :crash_report_queue
  @max_retries 3
  @initial_retry_delay 5_000
  @max_retry_delay 60_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Enqueues a crash report for async sending.
  """
  @spec enqueue(map()) :: :ok
  def enqueue(report) do
    GenServer.cast(__MODULE__, {:enqueue, report})
  end

  @doc """
  Returns the number of reports in the queue.
  """
  @spec count() :: non_neg_integer()
  def count do
    try do
      :ets.info(@table_name, :size) || 0
    rescue
      _ -> 0
    end
  end

  @doc """
  Processes all queued reports immediately (for testing).
  """
  @spec process_all() :: :ok
  def process_all do
    GenServer.call(__MODULE__, :process_all)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for persistent queue
    :ets.new(@table_name, [:named_table, :public, :ordered_set])

    # Schedule initial queue processing
    schedule_process_queue()

    {:ok, %{processing: false}}
  end

  @impl true
  def handle_cast({:enqueue, report}, state) do
    # Generate unique ID for the report
    report_id = generate_id()

    # Store in ETS with metadata
    entry = %{
      id: report_id,
      report: report,
      retries: 0,
      enqueued_at: System.monotonic_time(:second),
      last_attempt_at: nil
    }

    :ets.insert(@table_name, {report_id, entry})

    # Trigger immediate processing if not already processing
    unless state.processing do
      send(self(), :process_queue)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:process_all, _from, state) do
    process_queue(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:process_queue, state) do
    new_state = process_queue(state)

    # Schedule next processing
    schedule_process_queue()

    {:noreply, new_state}
  end

  # Private functions

  defp process_queue(state) do
    # Get all entries from queue
    entries =
      :ets.tab2list(@table_name)
      |> Enum.map(fn {_id, entry} -> entry end)
      |> Enum.sort_by(& &1.enqueued_at)

    if entries == [] do
      %{state | processing: false}
    else
      %{state | processing: true}
      |> process_entries(entries)
      |> Map.put(:processing, false)
    end
  end

  defp process_entries(state, []), do: state

  defp process_entries(state, [entry | rest]) do
    # Check if we should retry this entry
    if should_retry?(entry) do
      case Sender.send_report(entry.report) do
        {:ok, _} ->
          # Success - remove from queue
          :ets.delete(@table_name, entry.id)
          Logger.debug("Crash report #{entry.id} sent successfully")

        {:error, reason} ->
          # Failed - increment retry count
          updated_entry = %{
            entry
            | retries: entry.retries + 1,
              last_attempt_at: System.monotonic_time(:second)
          }

          if updated_entry.retries >= @max_retries do
            # Max retries exceeded - remove from queue
            :ets.delete(@table_name, entry.id)

            Logger.warning(
              "Crash report #{entry.id} failed after #{@max_retries} attempts, discarding",
              error: inspect(reason)
            )
          else
            # Update entry with new retry count
            :ets.insert(@table_name, {entry.id, updated_entry})

            Logger.debug(
              "Crash report #{entry.id} failed, will retry (#{updated_entry.retries}/#{@max_retries})",
              error: inspect(reason)
            )
          end
      end
    end

    process_entries(state, rest)
  end

  defp should_retry?(entry) do
    # Don't retry if max retries exceeded
    if entry.retries >= @max_retries do
      false
    else
      # Check if enough time has passed since last attempt
      if entry.last_attempt_at do
        delay = retry_delay(entry.retries)
        now = System.monotonic_time(:second)
        now - entry.last_attempt_at >= div(delay, 1000)
      else
        # Never attempted - should retry
        true
      end
    end
  end

  defp retry_delay(retries) do
    # Exponential backoff with max delay
    delay = @initial_retry_delay * :math.pow(2, retries)
    min(trunc(delay), @max_retry_delay)
  end

  defp schedule_process_queue do
    # Process queue every 30 seconds
    Process.send_after(self(), :process_queue, 30_000)
  end

  defp generate_id do
    # Generate a unique ID using timestamp and random bytes
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    "#{timestamp}-#{random}"
  end
end
