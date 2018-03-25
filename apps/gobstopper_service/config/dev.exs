use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure database
config :gobstopper_service, Gobstopper.Service.Repo,
    adapter: Ecto.Adapters.Postgres,
    username: "postgres",
    password: "postgres",
    database: "gobstopper_service_dev",
    hostname: "localhost",
    pool_size: 10

config :gobstopper_service, Gobstopper.Service.Token,
    allowed_algos: ["HS512"],
    token_verify_module: Guardian.Token.Jwt.Verify,
    issuer: "Gobstopper.Service",
    ttl: { 30, :days },
    allowed_drift: 2000,
    verify_issuer: true,
    secret_key: "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.e30.6bK5p0FPG1KY68mstRXiUjWtti5EbPmDg0QxP702j3WTEcI16GXZAU0NlXMQFnyPsrDyqCv9p6KRqMg7LcswMg"
