defmodule CodeDuels.Tournaments.Standings do
  @moduledoc """
  Standings and statistics computation for tournaments.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Repo
  alias CodeDuels.Tournaments
  alias CodeDuels.Tournaments.Duel

  def get_with_stats(tournament_id) do
    tournament = Tournaments.get_tournament!(tournament_id)

    participants =
      Tournaments.list_participants(tournament_id)
      |> Enum.filter(fn p ->
        p.role == "participant" or p.role == "organizer" or p.role == "volunteer" or
          p.role == "disqualified"
      end)
      |> Enum.sort_by(fn p -> {-p.score, p.id} end)
      |> Repo.preload(:user)

    duels =
      Repo.all(
        from d in Duel,
          where: d.tournament_id == ^tournament_id and d.status == "completed",
          preload: [:player_a, :player_b]
      )

    total_rounds = tournament.rounds_amount || 0

    rounds_scores =
      Repo.all(
        from r in CodeDuels.Tournaments.Round,
          where: r.tournament_id == ^tournament_id,
          select: {r.round_number, r.scores}
      )
      |> Map.new()

    participant_stats =
      for p <- participants do
        matches = Enum.filter(duels, fn d -> d.player_a_id == p.id or d.player_b_id == p.id end)

        {wins, draws, losses, round_results, total_penalty, tournament_points} =
          Enum.reduce(1..total_rounds, {0, 0, 0, [], 0, 0}, fn round_num,
                                                               {w, d, l, results, penalty_acc,
                                                                points_acc} ->
            match = Enum.find(matches, fn m -> m.round_number == round_num end)

            case match do
              nil ->
                {w, d, l, [{"-", ""} | results], penalty_acc, points_acc}

              m ->
                duel_scores = m.scores || [0, 0, 0, 0, 0]
                is_player_a = m.player_a_id == p.id
                round_problem_scores = Map.get(rounds_scores, round_num) || [1, 1, 2, 2, 3]

                {player_match_score, player_penalty, player_tournament_points} =
                  calculate_player_score(duel_scores, is_player_a, round_problem_scores)

                {opponent_match_score, _opponent_penalty, opponent_tournament_points} =
                  calculate_player_score(duel_scores, !is_player_a, round_problem_scores)

                match_result =
                  cond do
                    player_match_score > opponent_match_score -> "1"
                    player_match_score == opponent_match_score -> "0.5"
                    true -> "0"
                  end

                score_detail = "#{player_tournament_points}:#{opponent_tournament_points}"

                {w + if(player_match_score > opponent_match_score, do: 1, else: 0),
                 d + if(player_match_score == opponent_match_score, do: 1, else: 0),
                 l + if(player_match_score < opponent_match_score, do: 1, else: 0),
                 [{match_result, score_detail} | results], penalty_acc + player_penalty,
                 points_acc + player_tournament_points}
            end
          end)

        %{
          rank: 0,
          participant: p,
          user_id: p.user_id,
          name: (p.user && p.user.name) || (p.user && p.user.username) || "Unknown",
          username: (p.user && p.user.username) || "Unknown",
          score: wins + draws * 0.5,
          tournament_points: tournament_points,
          wins: wins,
          draws: draws,
          losses: losses,
          round_results: Enum.reverse(round_results),
          total_penalty: total_penalty
        }
      end

    Enum.with_index(participant_stats, 1)
    |> Enum.sort_by(fn {stats, _idx} ->
      {-stats.score, -stats.tournament_points, -stats.total_penalty, stats.participant.id}
    end)
    |> Enum.map(fn {stats, _idx} -> Map.put(stats, :rank, 0) end)
    |> Enum.with_index(1)
    |> Enum.map(fn {stats, idx} -> %{stats | rank: idx} end)
  end

  def calculate_player_score(duel_scores, is_player_a, tournament_problem_scores) do
    indices =
      if is_player_a do
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 0, do: i)
      else
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 1, do: i)
      end

    Enum.reduce(indices, {0, 0, 0}, fn idx, {match_score, penalty, tournament_points} ->
      value = Enum.at(duel_scores, idx) || 0
      problem_points = Enum.at(tournament_problem_scores, div(idx, 2)) || 0

      if is_player_a do
        if value < 0 do
          {match_score + abs(value), penalty + abs(value), tournament_points + problem_points}
        else
          {match_score, penalty, tournament_points}
        end
      else
        if value > 0 do
          {match_score + value, penalty + value, tournament_points + problem_points}
        else
          {match_score, penalty, tournament_points}
        end
      end
    end)
  end
end
