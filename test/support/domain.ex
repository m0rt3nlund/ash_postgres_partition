defmodule AshPostgresPartition.Test.Domain do
  use Ash.Domain

  resources do
    resource(AshPostgresPartition.Test.ResourceRange)
    resource(AshPostgresPartition.Test.ResourceList)
    resource(AshPostgresPartition.Test.ResourceHash)
    resource(AshPostgresPartition.Test.Tenant)
  end
end
