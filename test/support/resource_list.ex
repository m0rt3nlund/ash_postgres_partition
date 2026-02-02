defmodule AshPostgresPartition.Test.ResourceList do
  use Ash.Resource,
    domain: AshPostgresPartition.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPostgresPartition]

  attributes do
    uuid_v7_primary_key(:id)

    attribute(:key, :string, primary_key?: true, allow_nil?: false)
    attribute(:data, :string)

    update_timestamp(:updated_at, writable?: true)
    create_timestamp(:inserted_at, writable?: true)
  end

  postgres do
    table("resource_list")
    repo(AshPostgresPartition.Test.Repo)
  end

  actions do
    defaults([:create, :read])
    default_accept([:key, :data])
  end

  partition do
    type(:list)
    attribute(:key)
    name fn table, key -> {:ok, table <> "_" <> key} end
  end

  multitenancy do
    strategy(:context)
  end
end
