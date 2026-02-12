# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :langka_order_management,
 ecto_repos: [LangkaOrderManagement.Repo],
 generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :langka_order_management, LangkaOrderManagementWeb.Endpoint,
 url: [host: "localhost"],
 adapter: Bandit.PhoenixAdapter,
 render_errors: [
  formats: [json: LangkaOrderManagementWeb.ErrorJSON],
  layout: false
 ],
 pubsub_server: LangkaOrderManagement.PubSub,
 live_view: [signing_salt: "zhyP1XuF"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :langka_order_management, LangkaOrderManagement.Mailer, adapter: Swoosh.Adapters.Local

config :tesla, adapter: {Tesla.Adapter.Finch, name: FinchHttpClient}

# Configures Elixir's Logger
config :logger, :console,
 format: "$time $metadata[$level] $message\n",
 metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :cors_plug,
  headers: ["x-api-key"],
  expose: ["x-paging-total-count"]

config :langka_order_management, :telegram_integration,
  channel_id: System.get_env("TELEGRAM_CHANNEL_ID")

config :nadia,
  token: System.get_env("TELEGRAM_BOT_TOKEN"),
  base_url: System.get_env("TELEGRAM_API_BASE_URL")

config :langka_order_management, :supabase,
  server_url: System.get_env("SUPABASE_SERVER_URL"),
  api_key: System.get_env("SUPABASE_API_KEY")

config :langka_order_management, LangkaOrderManagement.Auth,
  jwt_alg: "RS256",
  private_key: System.get_env("JWT_PRIVATE_KEY"),
  public_key: System.get_env("JWT_PUBLIC_KEY")
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
