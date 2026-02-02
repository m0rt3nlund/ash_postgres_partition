defmodule AshPostgresPartition.Transformer do
  @moduledoc """
  This transformer sets up the resource for partitioning
  """

  use Spark.Dsl.Transformer
  require Logger

  @impl true
  def transform(dsl) do
    with type <- Spark.Dsl.Transformer.get_option(dsl, [:partition], :type),
         attribute <- Spark.Dsl.Transformer.get_option(dsl, [:partition], :attribute),
         {:ok, updated_dsl} <- maybe_set_create_table_options(dsl, type, attribute) do
      {:ok, updated_dsl}
    end
  end

  defp maybe_set_create_table_options(dsl, nil, _), do: {:ok, dsl}

  defp maybe_set_create_table_options(dsl, type, attribute) do
    dsl
    |> Spark.Dsl.Transformer.get_option([:postgres], :create_table_options)
    |> case do
      nil ->
        {:ok, create_table_options(dsl, type, attribute)}

      _ ->
        Logger.warning(
          "The resource #{Spark.Dsl.Transformer.get_persisted(dsl, :module)} has allready a value assigned for `postgres -> create_table_options`"
        )

        {:ok, dsl}
    end
  end

  defp create_table_options(dsl, :range, attribute) do
    dsl
    |> Spark.Dsl.Transformer.set_option([:postgres], :create_table_options, "PARTITION BY RANGE(#{attribute})")
  end

  defp create_table_options(dsl, :list, attribute) do
    dsl
    |> Spark.Dsl.Transformer.set_option([:postgres], :create_table_options, "PARTITION BY LIST(#{attribute})")
  end

  defp create_table_options(dsl, :hash, attribute) do
    dsl
    |> Spark.Dsl.Transformer.set_option([:postgres], :create_table_options, "PARTITION BY HASH(#{attribute})")
  end
end
