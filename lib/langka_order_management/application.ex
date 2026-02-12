defmodule LangkaOrderManagement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: FinchHttpClient},
      LangkaOrderManagementWeb.Telemetry,
      LangkaOrderManagement.Repo,
      {DNSCluster, query: Application.get_env(:langka_order_management, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LangkaOrderManagement.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LangkaOrderManagement.Finch},
      # Start a worker by calling: LangkaOrderManagement.Worker.start_link(arg)
      # {LangkaOrderManagement.Worker, arg},
      # Start to serve requests, typically the last entry
      LangkaOrderManagementWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LangkaOrderManagement.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LangkaOrderManagementWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
