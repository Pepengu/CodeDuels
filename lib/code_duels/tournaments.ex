defmodule CodeDuels.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Problems.Problem
  alias CodeDuels.Repo
  alias CodeDuels.Tournaments.{Tournament, Participant, Duel, Round, Submission}

  def list_open_tournaments do
    Repo.all(from t in Tournament, where: t.is_open == true)
  end

  def get_tournament!(id), do: Repo.get!(Tournament, id)

  def create_tournament(attrs \\ %{}) do
    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  def list_participants(tournament_id) do
    Repo.all(
      from p in Participant, where: p.tournament_id == ^tournament_id, order_by: [desc: p.score]
    )
  end

  def get_participant!(id), do: Repo.get!(Participant, id)

  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  def get_round(tournament_id, round_number) do
    Repo.one(
      from r in Round,
        where: r.tournament_id == ^tournament_id and r.round_number == ^round_number
    )
  end

  def get_round!(id), do: Repo.get!(Round, id)

  def create_submission(attrs \\ %{}) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> validate_code_not_empty()
    |> Repo.insert()
  end

  defp validate_code_not_empty(changeset) do
    Ecto.Changeset.validate_length(changeset, :code, min: 1)
  end

  def get_problemset(problemset) do
    problemset
    |> Enum.map(fn problem_id ->
      Repo.one(
        from p in Problem,
          where: p.id == ^problem_id
      )
    end)
  end

  def get_duels_for_round(tournament_id, round_number) do
    Repo.all(
      from d in Duel,
        where: d.tournament_id == ^tournament_id and d.round_number == ^round_number,
        preload: [:player_a, :player_b]
    )
  end

  def get_duel_for_user(tournament_id, round_number, user_id) do
    Repo.one(
      from d in Duel,
        join: pa in assoc(d, :player_a),
        join: pb in assoc(d, :player_b),
        where:
          d.tournament_id == ^tournament_id and d.round_number == ^round_number and
            (pa.user_id == ^user_id or pb.user_id == ^user_id),
        preload: [player_a: [:user], player_b: [:user]]
    )
  end

  def get_submissions_for_participants(participant_user_ids, round_id, problem_ids)
      when is_list(participant_user_ids) do
    submissions =
      Repo.all(
        from s in Submission,
          where: s.round_id == ^round_id and s.user_id in ^participant_user_ids,
          order_by: [desc: s.inserted_at],
          preload: [:user, :problem]
      )

    for user_id <- participant_user_ids do
      user_submissions =
        Enum.filter(submissions, fn s -> s.user_id == user_id end)

      problem_data =
        for problem_id <- problem_ids do
          user_prob_subs =
            Enum.filter(user_submissions, fn s -> s.problem_id == problem_id end)
            |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})

          {wrong_count, final_status, final_time} =
            cond do
              Enum.any?(user_prob_subs, fn s ->
                s.status == "accepted" or s.status == "solved"
              end) ->
                correct =
                  Enum.find(user_prob_subs, fn s ->
                    s.status == "accepted" or s.status == "solved"
                  end)

                wrong_before =
                  Enum.count(
                    Enum.take_while(user_prob_subs, fn s ->
                      s.id != correct.id and s.inserted_at <= correct.inserted_at
                    end),
                    fn s -> s.status != "accepted" and s.status != "solved" end
                  )

                {wrong_before, "solved", correct.inserted_at}

              user_prob_subs == [] ->
                {nil, "none", nil}

              Enum.any?(user_prob_subs, fn s -> s.status == "pending" end) ->
                last = List.first(user_prob_subs)
                wrong_count = Enum.count(Enum.drop(user_prob_subs, 1))
                {wrong_count, "pending", last.inserted_at}

              true ->
                last = List.first(user_prob_subs)
                wrong_count = Enum.count(user_prob_subs)
                {wrong_count, "unsolved", last.inserted_at}
            end

          {problem_id, %{wrong_count: wrong_count, status: final_status, time: final_time}}
        end

      {user_id, Map.new(problem_data)}
    end
    |> Map.new()
  end

  def get_all_user_submissions(user_id, round_id) do
    Repo.all(
      from s in Submission,
        where: s.user_id == ^user_id and s.round_id == ^round_id,
        order_by: [desc: s.inserted_at],
        preload: [:problem]
    )
  end

  def get_duels_for_tournament(tournament_id) do
    Repo.all(
      from d in Duel,
        where: d.tournament_id == ^tournament_id,
        order_by: [asc: d.round_number],
        preload: [player_a: [:user], player_b: [:user]]
    )
  end

  def create_duel(attrs \\ %{}) do
    %Duel{}
    |> Duel.changeset(attrs)
    |> Repo.insert()
  end

  def update_duel_scores(duel, player_a_score, player_b_score) do
    duel
    |> Duel.changeset(%{
      player_a_score: player_a_score,
      player_b_score: player_b_score,
      status: "completed"
    })
    |> Repo.update()
  end

  def record_match_result(duel_id, result) do
    duel = Repo.get!(Duel, duel_id) |> Repo.preload([:player_a, :player_b])

    {player_a_score, player_b_score} =
      case result do
        :a_wins -> {1.0, 0.0}
        :b_wins -> {0.0, 1.0}
        :draw -> {0.5, 0.5}
      end

    Repo.transaction(fn ->
      {:ok, updated_duel} =
        Repo.update(duel,
          set: [
            player_a_score: player_a_score,
            player_b_score: player_b_score,
            status: "completed"
          ]
        )

      Repo.update!(duel.player_a, set: [score: duel.player_a.score + player_a_score])
      Repo.update!(duel.player_b, set: [score: duel.player_b.score + player_b_score])

      updated_duel
    end)
  end

  def generate_pairings(tournament_id, round_number) do
    participants = list_participants(tournament_id) |> Enum.filter(&(&1.status == "active"))

    previous_duels =
      Repo.all(
        from d in Duel,
          where: d.tournament_id == ^tournament_id and d.round_number < ^round_number,
          select: {d.player_a_id, d.player_b_id}
      )

    paired_player_ids = MapSet.new(for {a, b} <- previous_duels, do: {a, b}, into: [])

    pairings = do_swiss_pairing(participants, paired_player_ids, round_number)

    Enum.map(pairings, fn {player_a, player_b} ->
      if player_b do
        attrs = %{
          tournament_id: tournament_id,
          round_number: round_number,
          player_a_id: player_a.id,
          player_b_id: player_b.id,
          status: "pending"
        }

        [create_duel(attrs)]
      else
        []
      end
    end)
    |> List.flatten()
  end

  defp do_swiss_pairing(participants, _previous_pairings, round_number) when round_number == 1 do
    participants
    |> Enum.sort_by(fn p -> {-p.score, p.id} end)
    |> Enum.chunk_every(2)
    |> Enum.reject(&(length(&1) == 1))
    |> Enum.map(fn chunk -> {Enum.at(chunk, 0), Enum.at(chunk, 1)} end)
  end

  defp do_swiss_pairing(participants, previous_pairings, _round_number) do
    participants = Enum.sort_by(participants, fn p -> {-p.score, p.id} end)

    score_groups = Enum.group_by(participants, fn p -> Float.round(p.score, 1) end)

    do_score_based_pairing(Map.values(score_groups), previous_pairings, [])
  end

  defp do_score_based_pairing([], _previous_pairings, acc) do
    Enum.reverse(acc)
  end

  defp do_score_based_pairing([group | rest], previous_pairings, acc) do
    {new_group, new_acc} = pair_group_with_bye_handling(group, previous_pairings, acc)
    do_score_based_pairing(rest, previous_pairings, new_acc ++ new_group)
  end

  defp pair_group_with_bye_handling(group, previous_pairings, accumulated) do
    used_ids = MapSet.new(for {a, b} <- accumulated, do: {a.id, b.id}, into: MapSet.new())

    group_ids = Enum.map(group, fn p -> p.id end)
    already_paired = Enum.filter(group_ids, fn id -> MapSet.member?(used_ids, id) end)
    remaining = Enum.reject(group, fn p -> Enum.member?(already_paired, p.id) end)

    {pairs, leftover} = pair_within_group(remaining, previous_pairings)

    used_in_pairs =
      MapSet.new(for {a, b} <- pairs ++ accumulated, do: {a.id, b.id}, into: MapSet.new())

    final_pairs =
      Enum.reduce(leftover, {pairs, used_in_pairs, []}, fn player,
                                                           {pairs_acc, used_acc, final_acc} ->
        case find_opponent(player, used_acc, accumulated ++ pairs_acc, previous_pairings) do
          nil ->
            {pairs_acc, used_acc, [{player, nil} | final_acc]}

          opponent ->
            {pairs_acc ++ [{player, opponent}], MapSet.put(used_acc, opponent.id), final_acc}
        end
      end)

    new_pairs = elem(final_pairs, 0)
    bye_pairs = elem(final_pairs, 2) |> Enum.reverse()
    {new_pairs ++ bye_pairs, accumulated ++ new_pairs}
  end

  defp pair_within_group(participants, previous_pairings) do
    participants = Enum.sort_by(participants, fn p -> {-p.score, p.id} end)
    pair_within_group_inner(participants, [], previous_pairings)
  end

  defp pair_within_group_inner([], acc, _), do: {Enum.reverse(acc), []}

  defp pair_within_group_inner(participants, acc, previous_pairings) do
    participants = Enum.sort_by(participants, fn p -> {-p.score, p.id} end)
    pair_within_group_inner(participants, acc, previous_pairings, 0)
  end

  defp pair_within_group_inner([p1 | rest], acc, _previous_pairings, _attempts) when rest == [] do
    {Enum.reverse(acc), [p1]}
  end

  defp pair_within_group_inner(participants, acc, previous_pairings, attempts)
       when attempts > 100 do
    {Enum.reverse(acc), participants}
  end

  defp pair_within_group_inner([p1, p2 | rest], acc, previous_pairings, attempts) do
    if has_played(p1.id, p2.id, previous_pairings) do
      if rest == [] do
        {Enum.reverse(acc), [p1, p2]}
      else
        [^p2 | new_rest] = rest
        pair_within_group_inner([p1 | new_rest] ++ [p2], acc, previous_pairings, attempts + 1)
      end
    else
      pair_within_group_inner(rest, [{p1, p2} | acc], previous_pairings, 0)
    end
  end

  defp find_opponent(player, used_ids, accumulated, previous_pairings) do
    accumulated
    |> Enum.filter(fn {a, b} ->
      (a.id == player.id or b.id == player.id) and
        not MapSet.member?(used_ids, if(a.id == player.id, do: b.id, else: a.id))
    end)
    |> Enum.map(fn {a, b} -> if a.id == player.id, do: b, else: a end)
    |> Enum.find(fn opponent ->
      not has_played(player.id, opponent.id, previous_pairings)
    end)
  end

  defp has_played(player_a_id, player_b_id, previous_pairings) do
    Enum.member?(previous_pairings, {player_a_id, player_b_id}) or
      Enum.member?(previous_pairings, {player_b_id, player_a_id})
  end

  def advance_round(tournament_id) do
    tournament = get_tournament!(tournament_id)

    if tournament.current_round < tournament.rounds_amount do
      new_round = tournament.current_round + 1

      tournament
      |> Ecto.Changeset.change(%{current_round: new_round, status: "in_progress"})
      |> Repo.update!()

      generate_pairings(tournament_id, new_round)

      {:ok, new_round}
    else
      tournament
      |> Ecto.Changeset.change(%{status: "completed"})
      |> Repo.update!()

      {:completed, tournament.rounds_amount}
    end
  end

  def get_standings(tournament_id) do
    list_participants(tournament_id)
    |> Enum.filter(fn p -> p.status == "active" end)
    |> Enum.sort_by(fn p -> {-p.score, p.id} end)
  end

  def get_standings_with_stats(tournament_id) do
    tournament = get_tournament!(tournament_id)
    participants = get_standings(tournament_id) |> Repo.preload(:user)

    duels =
      Repo.all(
        from d in Duel,
          where: d.tournament_id == ^tournament_id and d.status == "completed",
          preload: [:player_a, :player_b]
      )

    total_rounds = tournament.rounds_amount || 0
    tournament_problem_scores = tournament.scores || [1, 1, 2, 2, 3]

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

                {player_match_score, player_penalty, player_tournament_points} =
                  calculate_player_score(duel_scores, is_player_a, tournament_problem_scores)

                {opponent_match_score, _opponent_penalty, opponent_tournament_points} =
                  calculate_player_score(duel_scores, !is_player_a, tournament_problem_scores)

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

  defp calculate_player_score(duel_scores, is_player_a, tournament_problem_scores) do
    indices =
      if is_player_a do
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 0, do: i)
      else
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 1, do: i)
      end

    Enum.reduce(indices, {0, 0, 0}, fn idx, {match_score, penalty, tournament_points} ->
      value = Enum.at(duel_scores, idx) || 0
      problem_points = Enum.at(tournament_problem_scores, idx) || 0

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
