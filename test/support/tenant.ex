defmodule AshPostgresPartition.Test.Tenant do
  use Ash.Resource,
    domain: AshPostgresPartition.Test.Domain,
    data_layer: AshPostgres.DataLayer

  defimpl Ash.ToTenant do
    def to_tenant(%{id: id}, _resource \\ nil) do
      "tenant_#{id}"
    end
  end

  attributes do
    uuid_v7_primary_key(:id)

    attribute(:name, :string)

    update_timestamp(:updated_at, writable?: true)
    create_timestamp(:inserted_at, writable?: true)
  end

  actions do
    defaults([:create, :read])
    default_accept([:name])
  end

  postgres do
    table("tenant")
    repo(AshPostgresPartition.Test.Repo)

    manage_tenant do
      template(["tenant_", :id])
    end
  end
end
