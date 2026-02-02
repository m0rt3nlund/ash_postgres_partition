defmodule AshPostgresPartition.Info do
  @moduledoc false

  use Spark.InfoGenerator,
    extension: AshPostgresPartition,
    sections: [:partition]
end
