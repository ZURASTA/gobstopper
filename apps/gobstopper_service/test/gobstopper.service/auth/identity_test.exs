defmodule Gobstopper.Service.Auth.IdentityTest do
    use Gobstopper.Service.Case

    alias Gobstopper.Service.Auth.Identity
    alias Gobstopper.Service.Token

    describe "create/2" do
        test "creating a new account with a non-existent credential type" do
            assert_raise UndefinedFunctionError, fn ->
                Identity.create(:foo, nil)
            end
        end

        test "creating a new account using an email credential" do
            assert { :ok, _ } = Identity.create(:email, { "foo@bar", "secret" })
        end
    end

    describe "create/3" do
        test "creating a new account using an email credential" do
            assert { :error, "Invalid token" } == Identity.create(:email, { "foo@bar", "secret" }, nil)
        end

        test "creating an email credential when one is already associated" do
            { :ok, token } = Identity.create(:email, { "foo@bar", "secret" })
            assert { :error, "Failed to create credential" } == Identity.create(:email, { "foo@foo", "secret" }, token)
        end

        test "creating an email credential when none are associated" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert :ok == Identity.create(:email, { "foo@foo", "secret" }, token)
        end
    end

    describe "update/3" do
        test "update a non-existent identity's email credential" do
            assert { :error, "Invalid token" } == Identity.update(:email, { "foo@foo", "secret" }, nil)
        end

        test "update an identity's non-existent email credential" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert { :error, "No email credential exists" } == Identity.update(:email, { "foo@foo", "secret" }, token)
        end

        test "update an identity's existing email credential" do
            { :ok, token } = Identity.create(:email, { "foo@bar", "secret" })
            assert :ok == Identity.update(:email, { "foo@foo", "secret" }, token)
        end
    end

    describe "remove/2" do
        test "remove a non-existent identity's email credential" do
            assert { :error, "Invalid token" } == Identity.remove(:email, nil)
        end

        test "remove an identity's non-existent email credential" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert { :error, "No email credential exists" } == Identity.remove(:email, token)
        end

        test "remove an identity's existing email credential" do
            { :ok, token } = Identity.create(:email, { "foo@bar", "secret" })
            assert :ok == Identity.remove(:email, token)
        end
    end

    describe "login/2" do
        test "login with an bad email credential" do
            assert { :error, "Invalid credentials" } == Identity.login(:email, { "foo@bar", "secret" })
        end

        test "login with a good email credential" do
            { :ok, _ } = Identity.create(:email, { "foo@bar", "secret" })
            assert { :ok, _ } = Identity.login(:email, { "foo@bar", "secret" })
        end
    end

    describe "logout/2" do
        test "logout of a non-existent identity" do
            assert :ok == Identity.logout(nil)
        end

        test "logout of an identity" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert { :ok, false } == Identity.credential?(:email, token)
            assert :ok == Identity.logout(token)
            assert { :error, "Invalid token" } == Identity.credential?(:email, token)
        end
    end

    describe "refresh/1" do
        test "refresh a non-existent identity's token" do
            assert { :error, "Error refreshing token" } == Identity.refresh(nil)
        end

        test "refresh an identity's token" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)
            assert identity.identity == Identity.verify(token)

            assert { :ok, token2 } = Identity.refresh(token)
            assert nil == Identity.verify(token)
            assert identity.identity == Identity.verify(token2)
        end
    end

    describe "verify/1" do
        test "verify a non-existent identity" do
            assert nil == Identity.verify(nil)
        end

        test "verify of an identity" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert identity.identity == Identity.verify(token)
            Identity.logout(token)
            assert nil == Identity.verify(token)
        end
    end

    describe "credential?/2" do
        test "if a non-existent identity's email credential exists" do
            assert { :error, "Invalid token" } == Identity.credential?(:email, nil)
        end

        test "if an identity's non-existent email credential exists" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert { :ok, false } == Identity.credential?(:email, token)
        end

        test "if an identity's existing email credential exists" do
            { :ok, token } = Identity.create(:email, { "foo@bar", "secret" })
            assert { :ok, true } == Identity.credential?(:email, token)
        end
    end

    describe "all_credentials/1" do
        test "retrieving all credentials associated with a non-existent identity" do
            assert { :error, "Invalid token" } == Identity.all_credentials(nil)
        end

        test "retrieving all credentials associated with an identity with no credentials" do
            identity = Gobstopper.Service.Repo.insert!(Identity.Model.changeset(%Identity.Model{}))
            { :ok, token, _ } = Token.encode_and_sign(identity)

            assert { :ok, credentials } = Identity.all_credentials(token)
            assert Enum.all?(credentials, fn
                { _, { :none, nil } } -> true
                _ -> false
            end)
        end

        test "retrieving all credentials associated with an identity with an email credential" do
            { :ok, token } = Identity.create(:email, { "foo@bar", "secret" })
            assert { :ok, credentials } = Identity.all_credentials(token)
            assert Enum.any?(credentials, fn
                { :email, { :unverified, "foo@bar" } } -> true
                _ -> false
            end)
        end
    end
end
