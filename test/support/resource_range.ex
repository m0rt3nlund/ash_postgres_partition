defmodule AshPostgresPartition.Test.ResourceRange do
  use Ash.Resource,
    domain: AshPostgresPartition.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPostgresPartition]

  attributes do
    uuid_v7_primary_key(:id)

    attribute(:key, :utc_datetime_usec, primary_key?: true, allow_nil?: false)
    attribute(:data, :string)

    update_timestamp(:updated_at, writable?: true)
    create_timestamp(:inserted_at, writable?: true)
  end

  postgres do
    table("resource_range")
    repo(AshPostgresPartition.Test.Repo)
  end

  actions do
    defaults([:create, :read])
    default_accept([:key, :data])
  end

  partition do
    type(:range)
    attribute(:key)

    name fn table, {%DateTime{} = d1, %DateTime{} = d2} ->
      {:ok, table <> "_" <> "#{d1.year}_#{d1.month}_#{d1.day}__#{d2.year}_#{d2.month}_#{d2.day}"}
    end
  end

  multitenancy do
    strategy(:context)
  end
end
