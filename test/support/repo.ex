defmodule AshPostgresPartition.Test.Repo do
  use AshPostgres.Repo,
    otp_app: :ash_postgres_partition,
    adapter: Ecto.Adapters.Postgres

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def all_tenants() do
    []
  end

  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions", "pgcrypto"]
  end
end
