defmodule CodeDuels.Tournaments.Pairing do
  @moduledoc """
  Swiss-style pairing algorithm for tournaments.

  Fully decoupled from data access — receives participants and
  a create_duel callback as arguments.
  """

  @spec generate(integer(), integer(), [map()], MapSet.t(), (map ->
                                                               {:ok, term()} | {:error, term()})) ::
          [
            map()
          ]
  def generate(tournament_id, round_number, participants, previous_pairings, create_duel_fn) do
    pairings = do_swiss_pairing(participants, previous_pairings, round_number)

    Enum.map(pairings, fn {player_a, player_b} ->
      if player_b do
        attrs = %{
          tournament_id: tournament_id,
          round_number: round_number,
          player_a_id: player_a.id,
          player_b_id: player_b.id,
          status: "pending"
        }

        case create_duel_fn.(attrs) do
          {:ok, duel} -> [duel]
          _ -> []
        end
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

  defp pair_within_group_inner(participants, acc, _previous_pairings, attempts)
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
end
