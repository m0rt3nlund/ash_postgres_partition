defmodule AshPostgresPartition.Test.ResourceHash do
  use Ash.Resource,
    domain: AshPostgresPartition.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPostgresPartition]

  attributes do
    uuid_v7_primary_key(:id)

    attribute(:key, :integer, primary_key?: true, allow_nil?: false)
    attribute(:data, :string)

    update_timestamp(:updated_at, writable?: true)
    create_timestamp(:inserted_at, writable?: true)
  end

  postgres do
    table("resource_hash")
    repo(AshPostgresPartition.Test.Repo)
  end

  actions do
    defaults([:create, :read])
    default_accept([:key, :data])
  end

  partition do
    type(:hash)
    attribute(:key)
    opts(count: 5)

    name fn table, rem ->
      {:ok, table <> "_" <> "#{rem}"}
    end
  end

  multitenancy do
    strategy(:context)
  end
end
