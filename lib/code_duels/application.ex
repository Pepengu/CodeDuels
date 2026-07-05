defmodule CodeDuels.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CodeDuelsWeb.Telemetry,
      CodeDuels.Repo,
      {DNSCluster, query: Application.get_env(:code_duels, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CodeDuels.PubSub},
      CodeDuels.Tournaments.TournamentScheduler,
      {Task.Supervisor, name: CodeDuels.SubmissionTaskSupervisor},
      # Start a worker by calling: CodeDuels.Worker.start_link(arg)
      # {CodeDuels.Worker, arg},
      # Start to serve requests, typically the last entry
      CodeDuelsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CodeDuels.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CodeDuelsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
