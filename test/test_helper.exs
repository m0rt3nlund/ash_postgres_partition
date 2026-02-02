Application.ensure_all_started(:ash_postgres_partition)
ExUnit.start(capture_log: true)

AshPostgresPartition.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(AshPostgresPartition.Test.Repo, :manual)
