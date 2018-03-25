defmodule Gobstopper.Service.Auth.Identity do
    @moduledoc """
      Provides interfaces to identities.

      Requires operations that have restricted access, meet those requirements.
    """

    require Logger
    alias Gobstopper.Service.Auth.Identity
    alias Gobstopper.Service.Token

    defp unique_identity({ :error, %{ errors: [identity: _] } }), do: unique_identity(Gobstopper.Service.Repo.insert(Identity.Model.changeset(%Identity.Model{})))
    defp unique_identity(identity), do: identity

    @doc """
      Create an identity with the initial credential.

      Returns the session token on successful creation. Otherwise returns an
      error.
    """
    @spec create(atom, term) :: { :ok, String.t } | { :error, String.t }
    def create(type, credential) do
        with { :identity, { :ok, identity } } <- { :identity, unique_identity(Gobstopper.Service.Repo.insert(Identity.Model.changeset(%Identity.Model{}))) },
             { :create_credential, :ok } <- { :create_credential, Identity.Credential.create(type, identity, credential) },
             { :jwt, { :ok, jwt, _ } } <- { :jwt, Token.encode_and_sign(identity) } do
                { :ok, jwt }
        else
            { :identity, { :error, changeset } } ->
                Logger.debug("create identity: #{inspect(changeset.errors)}")
                { :error, "Failed to create credential" }
            { :create_credential, { :error, reason } } -> { :error, reason }
            { :jwt, { :error, _ } } -> { :error, "Could not create JWT" }
        end
    end

    @doc """
      Create a new credential to associate with an identity.

      Returns `:ok` on successful creation. Otherwise returns an error.
    """
    @spec create(atom, term, String.t) :: :ok | { :error, String.t }
    def create(type, credential, token) do
        with { :identity, identity = %Identity.Model{} } <- { :identity, verify_identity(token) },
             { :create_credential, :ok } <- { :create_credential, Identity.Credential.create(type, identity, credential) } do
                :ok
        else
            { :identity, nil } -> { :error, "Invalid token" }
            { :create_credential, { :error, reason } } -> { :error, reason }
        end
    end

    @doc """
      Update a credential associated with an identity.

      Returns `:ok` on successful update. Otherwise returns an error.
    """
    @spec update(atom, term, String.t) :: :ok | { :error, String.t }
    def update(type, credential, token) do
        case verify_identity(token) do
            nil -> { :error, "Invalid token" }
            identity -> Identity.Credential.change(type, identity, credential)
        end
    end

    @doc """
      Remove a credential associated with an identity.

      Returns `:ok` on successful removal. Otherwise returns an error.
    """
    @spec remove(atom, String.t) :: :ok | { :error, String.t }
    def remove(type, token) do
        case verify_identity(token) do
            nil -> { :error, "Invalid token" }
            identity -> Identity.Credential.revoke(type, identity)
        end
    end

    @doc """
      Login into an identity using the credential.

      Returns the session token on successful login. Otherwise returns an error.
    """
    @spec login(atom, term) :: { :ok, String.t } | { :error, String.t }
    def login(type, credential) do
        with { :identity, { :ok, identity } } <- { :identity, Identity.Credential.authenticate(type, credential) },
             { :jwt, { :ok, jwt, _ } } <- { :jwt, Token.encode_and_sign(identity) } do
                { :ok, jwt }
        else
            { :identity, { :error, reason } } -> { :error, reason }
            { :jwt, { :error, _ } } -> { :error, "Could not create JWT" }
        end
    end

    @doc """
      Logout of an identity's active session.

      Returns `:ok` on successful logout. Otherwise returns an error.
    """
    @spec logout(String.t) :: :ok | { :error, String.t }
    def logout(token) do
        case Token.remove(token) do
            { :ok, _ } -> :ok
            { :error, :invalid_token } -> :ok
            { :error, :not_found } -> :ok
            _ -> { :error, "Could not logout of session" }
        end
    end

    @doc """
      Refresh an active session token.

      Returns `{ :ok, token }` on successful refresh. Otherwise returns an error.
    """
    @spec refresh(String.t) :: { :ok, String.t } | { :error, String.t }
    def refresh(token) do
        case Token.refresh(token) do
            { :ok, _, { token, _ } } -> { :ok, token }
            _ -> { :error, "Error refreshing token" }
        end
    end

    @spec verify_identity(String.t) :: Identity.Model.t | nil
    defp verify_identity(token) do
        case Token.resource_from_token(token) do
            { :ok, identity, _ } -> identity
            _ -> nil
        end
    end

    @doc """
      Verify an identity's session.

      Returns the unique ID of the identity if verifying a valid session token.
      Otherwise returns `nil`.
    """
    @spec verify(String.t) :: String.t | nil
    def verify(token) do
        case verify_identity(token) do
            nil -> nil
            identity -> identity.identity
        end
    end

    @doc """
      Check if a credential type is associated with an identity.

      Returns whether the credential exists or not, if successful. Otherwise returns
      an error.
    """
    @spec credential?(atom, String.t) :: { :ok, boolean } | { :error, String.t }
    def credential?(type, token) do
        case verify_identity(token) do
            nil -> { :error, "Invalid token" }
            identity -> { :ok, Identity.Credential.credential?(type, identity) }
        end
    end

    @credential_types Enum.filter(for type <- Path.wildcard(Path.join(__DIR__, "identity/credential/*.ex")) do
        name = Path.basename(type)
        size = byte_size(name) - 3
        case name do
            <<credential :: size(size)-binary, ".ex">> -> String.to_atom(String.downcase(credential))
            _ -> nil
        end
    end, &(&1 != nil))

    @doc """
      Get the state of all credentials an identity could be associated with.

      Returns all the credentials presentable state if successful. Otherwise returns
      an error.
    """
    @spec all_credentials(String.t) :: { :ok, [{ atom, { :unverified | :verified, String.t } | { :none, nil } }] } | { :error, String.t }
    def all_credentials(token) do
        case verify_identity(token) do
            nil -> { :error, "Invalid token" }
            identity -> { :ok, (for type <- @credential_types, do: { type, Identity.Credential.info(type, identity) }) }
        end
    end
end
