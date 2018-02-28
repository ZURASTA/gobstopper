defmodule Gobstopper.Service.Auth do
    use GenServer

    alias Gobstopper.Service.Auth.Identity

    def child_spec(_args) do
        %{
            id: __MODULE__,
            start: { __MODULE__, :start_link, [] },
            type: :worker
        }
    end

    def start_link() do
        GenServer.start_link(__MODULE__, [], name: Application.get_env(:gobstopper_service, :server, &(&1)).(__MODULE__))
    end

    def handle_call({ :create, { type, credential } }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.create(type, credential)) end)
        { :noreply, state }
    end
    def handle_call({ :create, { type, credential }, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.create(type, credential, token)) end)
        { :noreply, state }
    end
    def handle_call({ :update, { type, credential }, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.update(type, credential, token)) end)
        { :noreply, state }
    end
    def handle_call({ :remove, { type }, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.remove(type, token)) end)
        { :noreply, state }
    end
    def handle_call({ :login, { type, credential } }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.login(type, credential)) end)
        { :noreply, state }
    end
    def handle_call({ :verify, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.verify(token)) end)
        { :noreply, state }
    end
    def handle_call({ :credential?, { type }, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.credential?(type, token)) end)
        { :noreply, state }
    end
    def handle_call({ :all_credentials, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.all_credentials(token)) end)
        { :noreply, state }
    end
    def handle_call({ :refresh, token }, from, state) do
        Task.start(fn -> GenServer.reply(from, Identity.refresh(token)) end)
        { :noreply, state }
    end
    def handle_call({ :swarm, :begin_handoff }, _from, state), do: { :reply, :restart, state }

    def handle_cast({ :logout, token }, state) do
        Task.start(fn -> Identity.logout(token) end)
        { :noreply, state }
    end
    def handle_cast({ :swarm, :end_handoff }, state), do: { :noreply, state }
    def handle_cast({ :swarm, :resolve_conflict, _state }, state), do: { :noreply, state }

    def handle_info({ :swarm, :die }, state), do: { :stop, :shutdown, state }
end
