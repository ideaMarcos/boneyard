import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :boneyard, Boneyard.Repo,
  database: Path.expand("../boneyard_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :boneyard, Oban, testing: :manual

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :boneyard, BoneyardWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qw/jmSerDeSIqZZOUxAPgBjh2ZUfU6SDiCT6ajVy3m19YKN3gDhAA0so7ae2ezMU",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
