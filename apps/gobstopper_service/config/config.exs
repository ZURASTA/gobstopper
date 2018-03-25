use Mix.Config

config :gobstopper_service,
    ecto_repos: [Gobstopper.Service.Repo]

config :guardian, Guardian.DB,
    repo: Gobstopper.Service.Repo,
    schema_name: "tokens",
    sweep_interval: 120


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
