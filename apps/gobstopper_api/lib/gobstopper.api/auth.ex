defmodule Gobstopper.API.Auth do
    @moduledoc """
      Handles the authorization of session tokens.
    """

    @service Gobstopper.Service.Auth

    @type token :: String.t
    @type uuid :: String.t

    @doc """
      Logout of an identity's active session.

      #{Gobstopper.API.option_docs}
    """
    @spec logout(token, keyword(any)) :: :ok
    def logout(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.cast(options[:server].(@service), { :logout, token })
        :ok
    end

    @doc """
      Verify an identity's session.

      #{Gobstopper.API.option_docs}

      Returns the unique ID of the identity if verifying a valid session token.
      Otherwise returns `nil`.
    """
    @spec verify(token, keyword(any)) :: uuid | nil
    def verify(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :verify, token }, options[:timeout])
    end

    @doc """
      Refresh an identity's session.

      #{Gobstopper.API.option_docs}

      Returns a new session token and disables the previous one. Otherwise returns
      an error.
    """
    @spec refresh(token, keyword(any)) :: { :ok, uuid } | { :error, String.t }
    def refresh(token, options \\ []) do
        options = Gobstopper.API.defaults(options)
        GenServer.call(options[:server].(@service), { :refresh, token }, options[:timeout])
    end
end
