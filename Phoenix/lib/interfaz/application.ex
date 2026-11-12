defmodule Interfaz.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Epicenter.Genserver, []},
      InterfazWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:interfaz, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Interfaz.PubSub},
      # Start a worker by calling: Interfaz.Worker.start_link(arg)
      # {Interfaz.Worker, arg},
      # Start to serve requests, typically the last entry
      InterfazWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Interfaz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InterfazWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
