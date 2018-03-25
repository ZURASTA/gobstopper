use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# Configure database
config :gobstopper_service, Gobstopper.Service.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: System.get_env("DATABASE_URL"),
    pool_size: 20

config :gobstopper_service, Gobstopper.Service.Token,
    allowed_algos: ["HS512"],
    token_verify_module: Guardian.Token.Jwt.Verify,
    issuer: "Gobstopper.Service",
    ttl: { 30, :days },
    allowed_drift: 2000,
    verify_issuer: true,
    secret_key: System.get_env("GUARDIAN_SECRET_KEY")
