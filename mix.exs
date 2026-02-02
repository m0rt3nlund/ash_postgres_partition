defmodule AshPostgresPartition.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/m0rt3nlund/ash_postgres_partition"

  def project do
    [
      app: :ash_postgres_partition,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      docs: &docs/0,
      source_url: @source_url
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description(),
    do: ~S"""
    Ash extension to help creating and checking for the existence of partitions
    """

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/m0rt3nlund/ash_postgres_partition"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spark, "~> 2.4"},
      {:ash_postgres, "~> 2.6"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:igniter, "~> 0.7"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.reset --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  def docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        {"documentation/dsls/DSL-AshPostgresPartition.md", search_data: Spark.Docs.search_data_for(AshPostgresPartition)}
      ],
      groups_for_modules: [
        Extension: [
          AshPostgresPartition
        ]
      ],
      groups_for_extras: [
        Reference: ~r"documentation/dsls"
      ],
      source_url_pattern: "#{@source_url}/blob/main/%{path}#L%{line}"
    ]
  end
end
