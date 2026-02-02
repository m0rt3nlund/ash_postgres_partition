defmodule AshPostgresPartition do
  @moduledoc """
  Ash Postgres Partition is an extension for Ash Resources
  It makes it easier to add partitions and to manage them
  It also supports having tenants
  """

  @partition %Spark.Dsl.Section{
    name: :partition,
    schema: [
      type: [
        type: {:or, [{:literal, :range}, {:literal, :list}, {:literal, :hash}]},
        required: true,
        doc: "Type of partitioning to use, possible values are `:range`, `:list` and `:hash`"
      ],
      attribute: [
        type: :atom,
        required: true,
        doc: "What attribute to use for partitioning"
      ],
      name: [
        type: {:fun, 2},
        required: true,
        doc: ~s"""
          Function to generate the name of the partition, expects {:ok, binary()}, the function is provided the table name and the key
        """
      ],
      generate_default_partition?: [
        type: :boolean,
        doc: "For `:range` and `:list` types this allows to generate a default partition for data not fitting into the specified values",
        default: false
      ],
      opts: [
        type: :keyword_list,
        keys: [
          count: [required: false, type: :integer, doc: "When using `:hash` type you must also provide the number of partitions"]
        ],
        default: [],
        doc: "When using `:hash` type, you must provide a `:count` option with number of partitions to create"
      ]
    ],
    describe: ~S"""
    Example of how to use this to add a `:list` type partition to a resource
    ```elixir
      defmodule MyResource do
        use Ash.Resource,
          domain: MyDomain,
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
          table("mytable")
          repo(MyRepo)
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
    ```
    """
  }

  use Spark.Dsl.Extension,
    sections: [@partition],
    transformers: [AshPostgresPartition.Transformer],
    verifiers: [AshPostgresPartition.Verifier]

  @spec exists?(resource :: module(), opts :: Keyword.t()) :: boolean()
  def exists?(resource, key, opts \\ []) do
    with {:ok, schema_name} <- schema_name(resource, Keyword.get(opts, :tenant)),
         {:ok, partition_name} <- partition_name(resource, key) do
      table_exists?(resource, schema_name, partition_name)
    end
  end

  @spec create(resource :: module(), opts :: Keyword.t()) :: boolean()
  def create(resource, key, opts \\ []) do
    with {:ok, repo} <- repo(resource),
         {:ok, schema_name} <- schema_name(resource, Keyword.get(opts, :tenant)),
         {:ok, table_name} <- table_name(resource),
         {:ok, type} <- type(resource),
         :ok <- validate_key(resource, type, key) do
      create_for(resource, repo, type, schema_name, table_name, key)
    end
  end

  defp table_exists?(resource, schema_name, partition_name) do
    with {:ok, repo} <- repo(resource) do
      repo
      |> Ecto.Adapters.SQL.query!(
        "select table_name from information_schema.tables t where t.table_schema = $1 and t.table_name = $2",
        [schema_name, partition_name]
      )
      |> case do
        %Postgrex.Result{num_rows: num_rows} when num_rows > 0 -> true
        _ -> false
      end
    end
  end

  defp create_for(resource, repo, :range, schema_name, table_name, {%DateTime{} = d1, %DateTime{} = d2} = key) do
    resource
    |> partition_name(key)
    |> case do
      {:ok, partition_name} ->
        if not table_exists?(resource, schema_name, partition_name) do
          execute(
            repo,
            "CREATE TABLE \"#{schema_name}\".\"#{partition_name}\" PARTITION OF \"#{schema_name}\".\"#{table_name}\" FOR VALUES FROM ('#{d1.year}-#{d1.month}-#{d1.day} #{d1.hour}:#{d1.minute}:#{d1.second}') TO ('#{d2.year}-#{d2.month}-#{d2.day} #{d2.hour}:#{d2.minute}:#{d2.second}')"
          )
        else
          :ok
        end
    end
  end

  defp create_for(resource, repo, :list, schema_name, table_name, key) do
    resource
    |> partition_name(key)
    |> case do
      {:ok, partition_name} ->
        if not table_exists?(resource, schema_name, partition_name) do
          execute(
            repo,
            "CREATE TABLE \"#{schema_name}\".\"#{partition_name}\" PARTITION OF \"#{schema_name}\".\"#{table_name}\" FOR VALUES IN('#{key}')"
          )
        else
          :ok
        end
    end
  end

  defp create_for(resource, repo, :hash, schema_name, table_name, _rem) do
    mod =
      resource
      |> AshPostgresPartition.Info.partition_opts!()
      |> Keyword.get(:count, 0)

    Enum.reduce_while(0..(mod - 1), :ok, fn remainder, _acc ->
      resource
      |> partition_name(remainder)
      |> case do
        {:ok, partition_name} ->
          if not table_exists?(resource, schema_name, partition_name) do
            execute(
              repo,
              "CREATE TABLE \"#{schema_name}\".\"#{partition_name}\" PARTITION OF \"#{schema_name}\".\"#{table_name}\" FOR VALUES WITH(MODULUS #{mod}, REMAINDER #{remainder})"
            )
            |> case do
              :ok -> {:cont, :ok}
              {:error, message} -> {:halt, message}
            end
          else
            :ok
          end
      end
    end)
  end

  defp execute(repo, query) do
    Ecto.Adapters.SQL.query(
      repo,
      query
    )
    |> case do
      {:ok, _} -> :ok
      _ -> {:error, "Unable to create partition"}
    end
  end

  defp partition_name(resource, key) do
    with {:ok, table_name} <- table_name(resource),
         {:ok, name_fn} <- AshPostgresPartition.Info.partition_name(resource) do
      name(resource, table_name, key, name_fn)
    end
  end

  defp name(resource, table_name, key, name_fn) when is_function(name_fn, 2) do
    name_fn.(table_name, key)
    |> case do
      {:ok, name} when is_binary(name) -> {:ok, name}
      _ -> {:error, "Expects `name` function in `#{resource}` to return {:ok, partition_name} where `partition_name` is a binary"}
    end
  end

  defp name(_resource, _table_name, _key, _invalid_fn), do: {:error, "Expects `name` to be a function with arity 2"}

  defp type(resource) do
    AshPostgresPartition.Info.partition_type(resource)
    |> case do
      :error -> {:error, "No partition type provided for `#{resource}`"}
      {:ok, type} -> {:ok, type}
    end
  end

  defp validate_key(_resource, :range, {%DateTime{} = d1, %DateTime{} = d2}) do
    if DateTime.before?(d1, d2) do
      :ok
    else
      {:error, "Invalid key provided for `:range`, expects first date to be before second"}
    end
  end

  defp validate_key(_resource, :range, _invalid), do: {:error, "Invalid key provided for `:range`, expects tuple with two DateTime"}

  defp validate_key(_resource, :list, key) when is_binary(key), do: :ok
  defp validate_key(_resource, :list, _invalid_key), do: {:error, "Invalid key provided for `:list`, expects a binary"}

  defp validate_key(_resource, :hash, _), do: :ok

  defp repo(resource) do
    AshPostgres.DataLayer.Info.repo(resource)
    |> case do
      nil -> {:error, "No repo provided for `#{resource}`"}
      repo -> {:ok, repo}
    end
  end

  defp schema_name(_resource, nil), do: "public"

  defp schema_name(resource, tenant) do
    tenant
    |> Ash.ToTenant.to_tenant(resource)
    |> case do
      nil -> {:ok, "public"}
      tenant -> {:ok, tenant}
    end
  end

  defp table_name(resource) do
    AshPostgres.DataLayer.Info.table(resource)
    |> case do
      nil -> {:error, "No table name provided for `#{resource}`"}
      name -> {:ok, name}
    end
  end
end
