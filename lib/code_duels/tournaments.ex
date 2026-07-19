defmodule CodeDuels.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Accounts.User
  alias CodeDuels.Problems.Problem
  alias CodeDuels.Repo
  alias CodeDuels.Tournaments.{Tournament, Participant, Duel, Round, Submission, Standings}

  def list_open_tournaments do
    Repo.all(from t in Tournament, where: t.is_open == true)
  end

  def list_tournaments_for_user(nil), do: list_open_tournaments()

  def list_tournaments_for_user(%User{is_admin: true}), do: Repo.all(Tournament)

  def list_tournaments_for_user(%User{id: user_id}) do
    open_ids = Repo.all(from t in Tournament, where: t.is_open == true, select: t.id)

    participant_ids =
      Repo.all(
        from p in Participant,
          join: t in assoc(p, :tournament),
          where: p.user_id == ^user_id and t.is_open == false,
          select: t.id
      )

    visible_ids = Enum.uniq(open_ids ++ participant_ids)
    Repo.all(from t in Tournament, where: t.id in ^visible_ids)
  end

  def get_tournament!(id), do: Repo.get!(Tournament, id)

  def create_tournament(attrs \\ %{}) do
    with {:ok, tournament} <-
           %Tournament{}
           |> Tournament.changeset(attrs)
           |> Repo.insert() do
      Task.start(fn -> CodeDuels.Typst.compile_for_tournament(tournament) end)
      {:ok, tournament}
    end
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

  def round_unlock_time(tournament, round_number) do
    if tournament.start_time do
      offset_seconds =
        (round_number - 1) * (tournament.round_time || 0) +
          (round_number - 1) * (tournament.intermission_time || 0)

      DateTime.add(tournament.start_time, offset_seconds, :second)
    else
      nil
    end
  end

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

  def get_submission!(id) do
    Repo.get!(Submission, id) |> Repo.preload([:user, :problem, :test_results])
  end

  def get_last_n_user_submissions(user_id, round_id, n) do
    Repo.all(
      from s in Submission,
        where: s.user_id == ^user_id and s.round_id == ^round_id,
        order_by: [desc: s.inserted_at],
        limit: ^n,
        preload: [:problem]
    )
  end

  def get_all_user_submissions(user_id, round_id) do
    Repo.all(
      from s in Submission,
        where: s.user_id == ^user_id and s.round_id == ^round_id,
        order_by: [desc: s.inserted_at],
        preload: [:problem]
    )
  end

  def get_all_user_submissions(user_id, round_id, problem_letter) do
    Repo.all(
      from s in Submission,
        join: p in assoc(s, :problem),
        where:
          s.user_id == ^user_id and
            s.round_id == ^round_id and
            s.problem_letter == ^problem_letter,
        order_by: [desc: s.inserted_at],
        preload: [:problem]
    )
  end

  def get_user_history(user_id) do
    Repo.all(
      from p in Participant,
        join: t in assoc(p, :tournament),
        where: p.user_id == ^user_id,
        order_by: [desc: p.inserted_at],
        preload: [:tournament]
    )
  end

  @doc """
  Aggregate submission statistics for a user based on successful (accepted) submissions.

  Returns a map with:
    * `:total_submissions` - count of all submissions by the user
    * `:accepted_submissions` - count of accepted submissions (status done + verdict accepted)
    * `:problems_solved` - count of distinct problems solved
    * `:languages` - list of `{language, accepted_count}` ordered by accepted count desc
  """
  def get_user_profile_stats(user_id) do
    total_submissions =
      Repo.one(from s in Submission, where: s.user_id == ^user_id, select: count(s.id)) || 0

    accepted =
      Repo.one(
        from s in Submission,
          where: s.user_id == ^user_id and s.status == :done and s.verdict == :accepted,
          select: %{
            count: count(s.id),
            problems: count(s.problem_id, :distinct)
          }
      )

    languages =
      Repo.all(
        from s in Submission,
          where: s.user_id == ^user_id and s.status == :done and s.verdict == :accepted,
          group_by: s.language,
          select: {s.language, count(s.id)},
          order_by: [desc: count(s.id)]
      )

    %{
      total_submissions: total_submissions,
      accepted_submissions: (accepted && accepted.count) || 0,
      problems_solved: (accepted && accepted.problems) || 0,
      languages: languages
    }
  end

  @doc """
  Computes a user's win/draw/loss record across all tournaments from completed duels.

  Returns a tuple `{aggregate, per_tournament}` where:
    * `aggregate` is `%{wins:, draws:, losses:, duels_played:}`
    * `per_tournament` is a map keyed by `tournament_id` with the same shape
  """
  def get_user_duel_stats(user_id) do
    participations = get_user_history(user_id)
    participant_ids = Enum.map(participations, & &1.id)

    if Enum.empty?(participant_ids) do
      {%{wins: 0, draws: 0, losses: 0, duels_played: 0}, %{}}
    else
      tournament_ids = Enum.map(participations, & &1.tournament_id)

      rounds_map =
        Repo.all(
          from r in Round,
            where: r.tournament_id in ^tournament_ids,
            select: {{r.tournament_id, r.round_number}, r.scores}
        )
        |> Map.new()

      duels =
        Repo.all(
          from d in Duel,
            where:
              d.status == "completed" and
                (d.player_a_id in ^participant_ids or d.player_b_id in ^participant_ids),
            preload: [:player_a, :player_b]
        )

      participant_id_set = MapSet.new(participant_ids)

      Enum.reduce(
        duels,
        {%{wins: 0, draws: 0, losses: 0, duels_played: 0}, %{}},
        fn duel, {agg_acc, per_acc} ->
          scores = duel.scores || []

          problem_scores =
            Map.get(rounds_map, {duel.tournament_id, duel.round_number}) || [1, 1, 2, 2, 3]

          is_player_a = MapSet.member?(participant_id_set, duel.player_a_id)

          {player_score, _, _} =
            Standings.calculate_player_score(scores, is_player_a, problem_scores)

          {opponent_score, _, _} =
            Standings.calculate_player_score(scores, not is_player_a, problem_scores)

          result =
            cond do
              player_score > opponent_score -> :win
              player_score == opponent_score -> :draw
              true -> :loss
            end

          agg_acc = %{
            agg_acc
            | wins: agg_acc.wins + if(result == :win, do: 1, else: 0),
              draws: agg_acc.draws + if(result == :draw, do: 1, else: 0),
              losses: agg_acc.losses + if(result == :loss, do: 1, else: 0),
              duels_played: agg_acc.duels_played + 1
          }

          current = Map.get(per_acc, duel.tournament_id, %{wins: 0, draws: 0, losses: 0})

          per_acc =
            Map.put(per_acc, duel.tournament_id, %{
              current
              | wins: current.wins + if(result == :win, do: 1, else: 0),
                draws: current.draws + if(result == :draw, do: 1, else: 0),
                losses: current.losses + if(result == :loss, do: 1, else: 0)
            })

          {agg_acc, per_acc}
        end
      )
    end
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

  def advance_round(tournament_id) do
    tournament = get_tournament!(tournament_id)

    if tournament.current_round < tournament.rounds_amount do
      new_round = tournament.current_round + 1

      tournament
      |> Ecto.Changeset.change(%{current_round: new_round, status: "in_progress"})
      |> Repo.update!()

      participants =
        list_participants(tournament_id)
        |> Enum.filter(
          &(&1.role == "participant" or &1.role == "organizer" or &1.role == "volunteer")
        )

      previous_duels =
        Repo.all(
          from d in Duel,
            where: d.tournament_id == ^tournament_id and d.round_number < ^new_round,
            select: {d.player_a_id, d.player_b_id}
        )

      paired_player_ids = MapSet.new(for {a, b} <- previous_duels, do: {a, b}, into: [])

      CodeDuels.Tournaments.Pairing.generate(
        tournament_id,
        new_round,
        participants,
        paired_player_ids,
        &CodeDuels.Tournaments.create_duel/1
      )

      {:ok, new_round}
    else
      tournament
      |> Ecto.Changeset.change(%{status: "completed"})
      |> Repo.update!()

      {:completed, tournament.rounds_amount}
    end
  end
end
