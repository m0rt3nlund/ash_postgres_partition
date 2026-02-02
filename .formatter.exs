# Used by "mix format"
[
  line_length: 150,
  plugins: [Spark.Formatter],
  import_deps: [:ecto, :ecto_sql, :ash_postgres],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}", "priv/repo/**/*.{ex}"]
]
