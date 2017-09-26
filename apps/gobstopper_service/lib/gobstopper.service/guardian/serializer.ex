defmodule Gobstopper.Service.Guardian.Serializer do
    @behaviour Guardian.Serializer

    def for_token(%Gobstopper.Service.Auth.Identity.Model{ identity: id }), do: { :ok, "Identity:#{id}" }
    def for_token(_), do: { :error, "Unknown resource type" }

    def from_token("Identity:" <> id), do: { :ok, Gobstopper.Service.Repo.get_by(Gobstopper.Service.Auth.Identity.Model, identity: id) }
    def from_token(_), do: { :error, "Unknown resource type" }
end
