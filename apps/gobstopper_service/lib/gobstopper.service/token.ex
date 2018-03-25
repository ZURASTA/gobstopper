defmodule Gobstopper.Service.Token do
    use Guardian, otp_app: :gobstopper_service

    def subject_for_token(%Gobstopper.Service.Auth.Identity.Model{ identity: id }, _), do: { :ok, "Identity:#{id}" }
    def subject_for_token(_, _), do: { :error, :unknown_resource }

    def resource_from_claims(%{ "sub" => "Identity:" <> id }), do: { :ok, Gobstopper.Service.Repo.get_by(Gobstopper.Service.Auth.Identity.Model, identity: id) }
    def resource_from_claims(_), do: { :error, :unknown_resource }

    def after_encode_and_sign(resource, claims, token, _) do
        case Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
            { :ok, _ } -> { :ok, token }
            err -> err
        end
    end

    def on_verify(claims, token, _) do
        case Guardian.DB.on_verify(claims, token) do
            { :ok, _ } -> { :ok, claims }
            err -> err
        end
    end

    def on_refresh(old, new, _) do
        case Guardian.DB.on_refresh(old, new) do
            { :ok, _, _ } -> { :ok, old, new }
            err -> err
        end
    end

    def on_revoke(claims, token, _) do
        case Guardian.DB.on_revoke(claims, token) do
            { :ok, _ } -> { :ok, claims }
            err -> err
        end
    end

    def remove(token, opts \\ []) do
        try do
            revoke(token, opts)
        rescue
            _ in [ArgumentError, Poison.SyntaxError] -> { :error, :invalid_token }
        end
    end
end
