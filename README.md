[![Stories in Ready](https://badge.waffle.io/ZURASTA/gobstopper.png?label=ready&title=Ready)](https://waffle.io/ZURASTA/gobstopper?utm_source=badge)
# Gobstopper (Identity and Credential Management)

Manages the identities and credentials used to authorise access to those identities. An identity is a unique ID representing an entity, that can then be used to associate other information with. It is connected to any number of credentials, which are used to prove the entity is who they say they are.


### Usage

The service component (`Gobstopper.Service`) is an OTP application that should be started prior to making any requests to the service. This component should only be interacted with to configure/control the service explicitly.

An API (`Gobstopper.API`) is provided to allow for convenient interaction with the service from external applications.


Credentials
-----------

A credential is a means of authentication, to prove an entity is who they say they are. There can be many types of credentials that an identity can be associated with, though an identity may only be associated with one credential for each type. Credentials associated with an identity can be managed by that identity,

Once an authentication attempt is made, if successful a token is created representing a valid authorisation to access that identity. This token can then be verified to retrieve the identity it represents (in order to expose to other services) or revoked to cause the token to no longer be valid.

Support for credentials can be added by implementing the behaviours in `Gobstopper.Service.Auth.Identity.Credential`.


### Email

Support for email based credentials is provided by the `Gobstopper.Service.Auth.Identity.Credential.Email` implementation.

This credential depends on the [`Sherbet`](https://github.com/ZURASTA/sherbet) contact service to manage the emails.

The credential works by allowing an identity to setup a login credential consisting of an email and password. The email used is the primary email associated with the identity in the [`Sherbet`](https://github.com/ZURASTA/sherbet) service.


Configuration
-------------

The service may be configured with the following options:

### Setup Mode

The service has two setup modes: `:auto` and `:manual`. When the service is started in `:auto`, it will automatically handle creating and migrating the database. When the service is started in `:manual`, the state of the database is left up to the user to manually setup.

By default the service runs in `:auto` mode. To change this behaviour, pass in the `{ :setup_mode, mode }` when starting the application.

### Database

The database options can be configured by providing the config for the key `Gobstopper.Service.Repo`.

For details on how to configure an [Ecto repo](https://hexdocs.pm/ecto/Ecto.Repo.html).

__Note:__ Relies on PostgreSQL for auto-generating UUIDs (uuid-ossp extension).
