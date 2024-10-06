defmodule Boneyard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BoneyardWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:boneyard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Boneyard.PubSub},
      {Registry, keys: :unique, name: Boneyard.GameRegistry},
      Boneyard.Presence,
      {DynamicSupervisor, strategy: :one_for_one, name: Boneyard.GameSupervisor},
      BoneyardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Boneyard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BoneyardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
