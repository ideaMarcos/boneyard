defmodule Boneyard.MixProject do
  use Mix.Project

  def project do
    [
      app: :boneyard,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      source_url: "https://github.com/ideaMarcos/boneyard"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Boneyard.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, ">= 0.0.0"},
      {:dns_cluster, ">= 0.0.0"},
      {:ecto_sql, ">= 0.0.0"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:esbuild, ">= 0.0.0", runtime: Mix.env() == :dev},
      {:floki, ">= 0.0.0", only: :test},
      {:gettext, ">= 0.0.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, ">= 0.0.0"},
      {:oban, ">= 0.0.0"},
      {:oban_web, ">= 0.0.0"},
      {:phoenix, ">= 0.0.0"},
      {:phoenix_ecto, ">= 0.0.0"},
      {:phoenix_html, ">= 0.0.0"},
      {:phoenix_live_dashboard, ">= 0.0.0"},
      {:phoenix_live_reload, ">= 0.0.0", only: :dev},
      {:phoenix_live_view, ">= 0.0.0"},
      {:tailwind, ">= 0.0.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, ">= 0.0.0"},
      {:telemetry_poller, ">= 0.0.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind boneyard", "esbuild boneyard"],
      "assets.deploy": [
        "tailwind boneyard --minify",
        "esbuild boneyard --minify",
        "phx.digest"
      ]
    ]
  end
end
