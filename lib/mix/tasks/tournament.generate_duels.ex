defmodule Mix.Tasks.Tournament.GenerateDuels do
  use Mix.Task
  import Ecto.Query
  alias CodeDuels.Tournaments
  alias CodeDuels.Repo
  alias CodeDuels.Tournaments.{Tournament, Duel}

  @shortdoc "Generate duels for a tournament"
  @moduledoc """
  Generate duels for a tournament by advancing to specified round.

  ## Examples

      mix tournament.duels 1         # advance tournament 1 to next round
      mix tournament.duels 1 5      # advance tournament 1 to round 5
      mix tournament.duels 1 reset   # reset tournament to round 0
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start", [])

    case args do
      [] ->
        Mix.shell().error("Please provide tournament_id")
        Mix.shell().info("Usage: mix tournament.duels <tournament_id> [round_number|reset]")

      [tournament_id, "reset"] ->
        {tid, _} = Integer.parse(tournament_id)
        reset_tournament(tid)

      [tournament_id, round_number] ->
        {tid, _} = Integer.parse(tournament_id)
        {rnum, _} = Integer.parse(round_number)
        generate_duels(tid, rnum)

      [tournament_id] ->
        {tid, _} = Integer.parse(tournament_id)
        advance_tournament(tid)
    end
  end

  defp reset_tournament(tournament_id) do
    tournament = Repo.get!(Tournament, tournament_id)
    IO.puts("Reset tournament: #{tournament.name}")

    tournament |> Ecto.Changeset.change(%{current_round: 0, status: "setup"}) |> Repo.update!()

    query = from d in Duel, where: d.tournament_id == ^tournament_id
    Repo.delete_all(query)

    IO.puts("Reset to round 0, deleted all duels")
  end

  defp advance_tournament(tournament_id) do
    tournament = Repo.get!(Tournament, tournament_id)
    IO.puts("Tournament: #{tournament.name}")
    IO.puts("Status: #{tournament.status}")
    IO.puts("Current round: #{tournament.current_round}")

    result = Tournaments.advance_round(tournament_id)
    IO.inspect(result, label: "Advance result")

    new_round = tournament.current_round + 1
    duels = Tournaments.get_duels_for_round(tournament_id, new_round)
    IO.puts("Duels created for round #{new_round}: #{length(duels)}")
  end

  defp generate_duels(tournament_id, round_number) do
    tournament = Repo.get!(Tournament, tournament_id)
    current = tournament.current_round

    IO.puts("Tournament: #{tournament.name}")
    IO.puts("Current round: #{current}, target: #{round_number}")

    if round_number > current do
      for r <- (current + 1)..round_number do
        IO.puts("\n--- Advancing to round #{r} ---")
        result = Tournaments.advance_round(tournament_id)
        IO.inspect(result, label: "Round #{r} result")

        duels = Tournaments.get_duels_for_round(tournament_id, r)
        IO.puts("Created #{length(duels)} duels")
      end
    else
      IO.puts("Target round must be greater than current round")
    end
  end
end
