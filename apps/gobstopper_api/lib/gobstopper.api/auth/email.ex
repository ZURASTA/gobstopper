defmodule Gobstopper.API.Auth.Email do
    @moduledoc """
      Handles the management of email authorization credentials.
    """

    @service Gobstopper.Service.Auth
    @credential_type :email

    alias Gobstopper.API.Auth

    @doc """
      Create a new identity initially associated with the given email credential.

      #{Gobstopper.API.option_docs}

      Returns the session token on successful creation. Otherwise returns an
      error.
    """
    @spec register(String.t, String.t, keyword(any)) :: { :ok, Auth.token } | { :error, String.t }
    def register(email, pass, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :create, { @credential_type, { email, pass } } }, options[:timeout])
    end

    @doc """
      Get the current email credential associated with the identity.

      #{Gobstopper.API.option_docs}

      Returns the state of the credential if one exists or does not exist. Otherwise
      returns an error.
    """
    @spec get(Auth.token, keyword(any)) :: { :ok, { :unverified | :verified, String.t } | { :none, nil } } | { :error, String.t }
    def get(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        case GenServer.call(options[:server].(@service), { :all_credentials, token }, options[:timeout]) do
            { :ok, credentials } -> { :ok, credentials[@credential_type] }
            error -> error
        end
    end

    @doc """
      Associate an email credential with the identity, replacing the old email
      credential.

      #{Gobstopper.API.option_docs}

      Returns `:ok` on successful creation. Otherwise returns an error.
    """
    @spec set(Auth.token, String.t, String.t, keyword(any)) :: :ok | { :error, String.t }
    def set(token, email, pass, options \\ []) do
        credential = { @credential_type, { email, pass } }

        options = Gobstopper.API.defaults(options)
        service = Gobstopper.API.defaults(options)[:server].(@service)
        with { :error, _update_error } <- GenServer.call(service, { :update, credential, token }, options[:timeout]),
             { :error, create_error } <- GenServer.call(service, { :create, credential, token }, options[:timeout]) do
                { :error, create_error }
        else
            :ok -> :ok
        end
    end

    @doc """
      Remove the email credential associated with the identity.

      #{Gobstopper.API.option_docs}

      Returns `:ok` on successful removal. Otherwise returns an error.
    """
    @spec remove(Auth.token, keyword(any)) :: :ok | { :error, String.t }
    def remove(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :remove, { @credential_type }, token }, options[:timeout])
    end

    @doc """
      Check if an email credential is associated with the identity.

      #{Gobstopper.API.option_docs}

      Returns whether the credential exists or not, if successful. Otherwise returns
      an error.
    """
    @spec exists?(Auth.token, keyword(any)) :: { :ok, boolean } | { :error, String.t }
    def exists?(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :credential?, { @credential_type }, token }, options[:timeout])
    end

    @doc """
      Login into an identity using the email credential.

      #{Gobstopper.API.option_docs}

      Returns the session token on successful login. Otherwise returns an error.
    """
    @spec login(String.t, String.t, keyword(any)) :: { :ok, Auth.token } | { :error, String.t }
    def login(email, pass, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :login, { @credential_type, { email, pass } } }, options[:timeout])
    end
end
