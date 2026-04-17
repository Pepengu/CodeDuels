defmodule CodeDuels.Tournaments.TournamentScheduler do
  use GenServer
  require Logger

  alias CodeDuels.Tournaments

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_next_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_tournaments, state) do
    check_and_start_rounds()
    schedule_next_check()
    {:noreply, state}
  end

  defp schedule_next_check() do
    Process.send_after(self(), :check_tournaments, 30_000)
  end

  defp check_and_start_rounds() do
    Tournaments.list_open_tournaments()
    |> Enum.each(fn tournament ->
      if tournament.status == "setup" && tournament.start_time do
        now = DateTime.utc_now()

        if DateTime.compare(now, tournament.start_time) == :gt do
          Tournaments.advance_round(tournament.id)
        end
      end

      if tournament.status == "in_progress" && tournament.start_time do
        tournament = Tournaments.get_tournament!(tournament.id)
        round_start_time = calculate_round_start_time(tournament)
        now = DateTime.utc_now()

        if round_start_time && DateTime.compare(now, round_start_time) == :gt do
          Tournaments.advance_round(tournament.id)
        end
      end
    end)
  end

  defp calculate_round_start_time(tournament) do
    round_duration = tournament.round_time + tournament.intermission_time
    seconds_for_rounds = tournament.current_round * round_duration
    DateTime.add(tournament.start_time, seconds_for_rounds, :second)
  end
end
