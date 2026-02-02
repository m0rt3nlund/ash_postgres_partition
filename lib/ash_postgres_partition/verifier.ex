defmodule AshPostgresPartition.Verifier do
  @behaviour Spark.Dsl.Verifier

  @impl true
  def verify(dsl) do
    with resource <- Spark.Dsl.Verifier.get_persisted(dsl, :module),
         type <- Spark.Dsl.Verifier.get_option(dsl, [:partition], :type),
         attribute <- Spark.Dsl.Verifier.get_option(dsl, [:partition], :attribute),
         :ok <- verify_attribute(resource, attribute),
         :ok <- maybe_verify_hash_partition_count(dsl, type),
         :ok <- verify_attribute(resource, attribute) do
      :ok
    end
  end

  defp verify_attribute(resource, attribute) do
    Ash.Resource.Info.attribute(resource, attribute)
    |> case do
      nil -> {:error, "`#{attribute}` is not a valid attrIbute on resource `#{resource}`"}
      _ -> :ok
    end
  end

  defp maybe_verify_hash_partition_count(dsl, :hash) do
    dsl
    |> Spark.Dsl.Verifier.get_option([:partition], :opts)
    |> Keyword.get(:count)
    |> case do
      nil -> {:error, "You must provide `opts` with `count` for `:hash` type"}
      _ -> :ok
    end
  end

  defp maybe_verify_hash_partition_count(_dsl, _), do: :ok
end
