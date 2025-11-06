# Limit concurrent test execution for SQLite compatibility
# SQLite doesn't handle high concurrency well, even with WAL mode
# Using 4 concurrent cases to ensure database stability
ExUnit.start(max_cases: 4)
Ecto.Adapters.SQL.Sandbox.mode(Mydia.Repo, :manual)

# Configure ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)
