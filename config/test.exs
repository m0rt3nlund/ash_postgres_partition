import Config

config :ash_postgres_partition,
  ash_domains: [
    AshPostgresPartition.Test.Domain
  ]

config :ash_postgres_partition,
  ecto_repos: [AshPostgresPartition.Test.Repo]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ash_postgres_partition, AshPostgresPartition.Test.Repo,
  username: "maskon",
  password: "maskon",
  hostname: "localhost",
  database: "ash_postgres_partition_test_#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 4,
  migration_primary_key: false,
  migration_foreign_key: [column: :id, type: :binary_id]

config :ash, disable_async?: true
