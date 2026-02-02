defmodule AshPostgresPartitionTest do
  use AshPostgresPartition.Test.RepoCase
  doctest AshPostgresPartition

  test "Create range partition" do
    assert %AshPostgresPartition.Test.Tenant{} = tenant = Ash.create!(AshPostgresPartition.Test.Tenant, %{name: "Test"})

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceRange, {~U[2025-01-01 00:00:00.00Z], ~U[2026-01-01 00:00:00.00Z]},
             tenant: tenant
           ) == false

    assert :ok =
             AshPostgresPartition.create(AshPostgresPartition.Test.ResourceRange, {~U[2025-01-01 00:00:00.00Z], ~U[2026-01-01 00:00:00.00Z]},
               tenant: tenant
             )

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceRange, {~U[2025-01-01 00:00:00.00Z], ~U[2026-01-01 00:00:00.00Z]},
             tenant: tenant
           ) == true

    assert %AshPostgresPartition.Test.ResourceRange{} =
             _resource = Ash.create!(AshPostgresPartition.Test.ResourceRange, %{key: ~U[2025-05-01 00:00:00.00Z], data: "data"}, tenant: tenant)
  end

  test "Create list partition" do
    assert %AshPostgresPartition.Test.Tenant{} = tenant = Ash.create!(AshPostgresPartition.Test.Tenant, %{name: "Test"})

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceList, "partition_1", tenant: tenant) == false

    assert :ok = AshPostgresPartition.create(AshPostgresPartition.Test.ResourceList, "partition_1", tenant: tenant)

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceList, "partition_1", tenant: tenant) == true

    assert %AshPostgresPartition.Test.ResourceList{} =
             _resource = Ash.create!(AshPostgresPartition.Test.ResourceList, %{key: "partition_1", data: "data"}, tenant: tenant)
  end

  test "Create hash partition" do
    assert %AshPostgresPartition.Test.Tenant{} = tenant = Ash.create!(AshPostgresPartition.Test.Tenant, %{name: "Test"})

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceHash, 4, tenant: tenant) == false

    assert :ok = AshPostgresPartition.create(AshPostgresPartition.Test.ResourceHash, 4, tenant: tenant)

    assert AshPostgresPartition.exists?(AshPostgresPartition.Test.ResourceHash, 4, tenant: tenant) == true

    assert %AshPostgresPartition.Test.ResourceHash{} =
             _resource = Ash.create!(AshPostgresPartition.Test.ResourceHash, %{key: 3, data: "data"}, tenant: tenant)
  end
end
