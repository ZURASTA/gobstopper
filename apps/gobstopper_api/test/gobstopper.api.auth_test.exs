defmodule Gobstopper.API.AuthTest do
    use Gobstopper.Service.Case

    alias Gobstopper.API.Auth

    test "invalid token logout" do
        assert :ok == Auth.logout(nil)
    end

    test "verify invalid token" do
        assert nil == Auth.verify(nil)
    end

    test "valid token logout and verify" do
        { :ok, token } = Auth.Email.register("foo@bar", "secret")
        assert nil != Auth.verify(token)
        assert :ok == Auth.logout(token)
        :timer.sleep(100)
        assert nil == Auth.verify(token)
    end

    test "valid token refresh and verify" do
        { :ok, token } = Auth.Email.register("foo@bar", "secret")
        identity = Auth.verify(token)
        assert { :ok, token2 } = Auth.refresh(token)
        assert nil == Auth.verify(token)
        assert identity == Auth.verify(token2)
    end

    describe "all_credentials/1" do
        test "retrieving all credentials associated with a non-existent identity" do
            assert { :error, "Invalid token" } == Auth.all_credentials(nil)
        end

        test "retrieving all credentials associated with an identity with no credentials" do
            identity = Gobstopper.Service.Repo.insert!(Gobstopper.Service.Auth.Identity.Model.changeset(%Gobstopper.Service.Auth.Identity.Model{}))
            { :ok, token, _ } = Guardian.encode_and_sign(identity)

            assert { :ok, credentials } = Auth.all_credentials(token)
            assert Enum.all?(credentials, fn
                { _, { :none, nil } } -> true
                _ -> false
            end)
        end

        test "retrieving all credentials associated with an identity with an email credential" do
            { :ok, token } = Auth.Email.register("foo@bar", "secret")
            assert { :ok, credentials } = Auth.all_credentials(token)
            assert Enum.any?(credentials, fn
                { :email, { :unverified, "foo@bar" } } -> true
                _ -> false
            end)
        end
    end
end
