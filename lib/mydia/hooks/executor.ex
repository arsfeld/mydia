defmodule Mydia.Hooks.Executor do
  @moduledoc """
  Coordinates hook execution with timeout, error handling, and result aggregation.
  """

  require Logger
  alias Mydia.Hooks.{Manager, LuaExecutor}

  @doc """
  Execute hooks synchronously, returning the modified data.
  """
  def execute_sync(event, data, opts \\ []) do
    hooks = Manager.list_hooks(event)
    config = Application.get_env(:mydia, :runtime_config, %{hooks: %{default_timeout_ms: 5000}})

    default_timeout =
      case config do
        %Mydia.Config.Schema{hooks: hooks} when not is_nil(hooks) ->
          hooks.default_timeout_ms || 5000

        %{hooks: %{default_timeout_ms: timeout}} when is_integer(timeout) ->
          timeout

        %{hooks: hooks} when is_map(hooks) ->
          Map.get(hooks, :default_timeout_ms, 5000)

        _ ->
          5000
      end

    timeout = Keyword.get(opts, :timeout, default_timeout)

    Logger.debug("Executing #{length(hooks)} hook(s) for event: #{event}")

    result =
      Enum.reduce_while(hooks, {:ok, data}, fn hook, {:ok, acc_data} ->
        case execute_hook(hook, event, acc_data, timeout: timeout) do
          {:ok, %{modified: true, changes: changes} = result} ->
            Logger.info("Hook #{hook.name} modified data: #{result[:message]}")
            merged_data = deep_merge(acc_data, changes)
            {:cont, {:ok, merged_data}}

          {:ok, %{modified: false}} ->
            Logger.debug("Hook #{hook.name} did not modify data")
            {:cont, {:ok, acc_data}}

          {:error, reason} ->
            Logger.warning("Hook #{hook.name} failed: #{inspect(reason)}")
            # Fail-soft: continue with next hook
            {:cont, {:ok, acc_data}}
        end
      end)

    result
  end

  @doc """
  Execute hooks asynchronously (fire and forget).
  """
  def execute_async(event, data, opts \\ []) do
    repo_config = Mydia.Repo.config()

    if repo_config[:pool] == Ecto.Adapters.SQL.Sandbox do
      # In test environment with sandbox, run synchronously to avoid connection issues
      execute_sync(event, data, opts)
    else
      # In production, run asynchronously
      Task.Supervisor.start_child(Mydia.TaskSupervisor, fn ->
        execute_sync(event, data, opts)
      end)
    end

    :ok
  end

  # Private Functions

  defp execute_hook(hook, event, data, opts) do
    case hook.type do
      :lua ->
        execute_lua_hook(hook, event, data, opts)

      :external ->
        execute_external_hook(hook, event, data, opts)

      _ ->
        {:error, :unsupported_hook_type}
    end
  end

  defp execute_lua_hook(hook, event, data, opts) do
    config = Application.get_env(:mydia, :runtime_config, %{hooks: %{default_timeout_ms: 5000}})

    default_timeout =
      case config do
        %Mydia.Config.Schema{hooks: hooks} when not is_nil(hooks) ->
          hooks.default_timeout_ms || 5000

        %{hooks: %{default_timeout_ms: timeout}} when is_integer(timeout) ->
          timeout

        %{hooks: hooks} when is_map(hooks) ->
          Map.get(hooks, :default_timeout_ms, 5000)

        _ ->
          5000
      end

    timeout = Keyword.get(opts, :timeout, default_timeout)

    event_data = %{
      event: event,
      timestamp: DateTime.utc_now(),
      data: data,
      context: %{}
    }

    LuaExecutor.execute_file(hook.path, event_data, timeout: timeout)
  end

  defp execute_external_hook(_hook, _event, _data, _opts) do
    # TODO: Implement external process execution
    {:error, :not_implemented}
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right
end
