defmodule CodeDuelsWeb.PairingsLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <.tournament_header tournament={@tournament} active_tab="pairings" />

        <div class="flex flex-wrap gap-1 mb-0">
          <%= for round <- @available_rounds do %>
            <.link
              navigate={"/#{@tournament.id}/pairings?round=#{round}"}
              class={"px-4 py-2 rounded-t-lg font-medium transition-colors #{if @selected_round == round, do: "bg-base-100 text-base-content border-t border-x border-base-300", else: "bg-base-200 text-base-content/70 hover:bg-base-300 hover:text-base-content"}"}
            >
              Раунд {round}
            </.link>
          <% end %>
        </div>

        <div class="border border-base-300 rounded-b-lg rounded-tr-lg p-4">
          <%= if @selected_round do %>
            <% duels = Map.get(@duels_by_round, @selected_round, []) %>
            <%= if duels != [] do %>
              <div class="overflow-visible">
                <table class="table table-zebra w-auto">
                  <thead>
                    <tr>
                      <th>Игрок A</th>
                      <th>Штраф A</th>
                      <th>Игрок B</th>
                      <th>Штраф A</th>
                      <%= for i <- 0..(@tournament.problems_per_round || 5) - 1 do %>
                        <th>
                          <div>Задача {i + 1}</div>
                          <div class="text-xs text-gray-500 font-normal">
                            Вес {Enum.at(@tournament.scores, i)}
                          </div>
                        </th>
                      <% end %>
                      <th>Всего</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for duel <- duels do %>
                      <% is_current_user =
                        @current_user &&
                          (duel.player_a.user_id == @current_user.id ||
                             duel.player_b.user_id == @current_user.id) %>
                      <tr class="hover">
                        <td class={cell_class("text-blue-500", is_current_user)}>
                          {player_name(duel.player_a)}
                        </td>
                        <td class={cell_class(nil, is_current_user)}>
                          {player_penality(duel.scores, :A)}
                        </td>
                        <td class={cell_class("text-red-500", is_current_user)}>
                          {player_name(duel.player_b)}
                        </td>
                        <td class={cell_class(nil, is_current_user)}>
                          {player_penality(duel.scores, :B)}
                        </td>
                        <%= for i <- 0..(@tournament.problems_per_round || 5) - 1 do %>
                          <% score = problem_display(duel.scores, i) %>
                          <td class={
                            cell_class("font-mono", is_current_user) ++
                              case score do
                                x when x < 0 -> ["text-blue-500"]
                                x when x > 0 -> ["text-red-500"]
                                0 -> []
                              end
                          }>
                            {case score do
                              0 -> "-"
                              x when x > 0 -> "#{x}"
                              x when x < 0 -> "#{-x}"
                            end}
                          </td>
                        <% end %>
                        <% score = duel_total(duel.scores, @tournament.scores) %>
                        <td class={
                          cell_class("font-mono font-semibold", is_current_user) ++
                            if score != "-:-" do
                              [a, b] = String.split(score, ":") |> Enum.map(&String.to_integer/1)

                              case {a, b} do
                                {x, y} when x == y -> ["text-yellow-500"]
                                {x, y} when x > y -> ["text-red-500"]
                                {x, y} when x < y -> ["text-blue-500"]
                              end
                            else
                              []
                            end
                        }>
                          {score}
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <div class="text-center py-12 opacity-70">
                <p class="text-xl">Нет данных за раунд {@selected_round}</p>
              </div>
            <% end %>
          <% else %>
            <div class="text-center py-12 opacity-70">
              <p class="text-xl">Нет данных</p>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp cell_class(base_class, highlight?) do
    if highlight? do
      List.wrap(base_class) ++ ["bg-yellow-500/10"]
    else
      List.wrap(base_class)
    end
  end

  defp player_name(nil), do: "BYE"

  defp player_name(participant) do
    if participant.user do
      participant.user.name || participant.user.username || "Player ##{participant.id}"
    else
      "Player ##{participant.id}"
    end
  end

  defp player_penality(scores, :A) do
    "#{scores |> Enum.reduce(0, fn val, acc -> if val < 0, do: acc - val, else: acc end)}"
  end

  defp player_penality(scores, :B) do
    "#{scores |> Enum.reduce(0, fn val, acc -> if val > 0, do: acc + val, else: acc end)}"
  end

  defp problem_display(nil, _idx), do: {nil, "-"}

  defp problem_display(scores, idx) do
    cond do
      idx >= length(scores) ->
        0

      Enum.at(scores, idx) && Enum.at(scores, idx) < 0 ->
        Enum.at(scores, idx)

      Enum.at(scores, idx) && Enum.at(scores, idx) > 0 ->
        Enum.at(scores, idx)

      true ->
        0
    end
  end

  defp duel_total(nil, _problem_scores), do: "-:-"

  defp duel_total(scores, problem_scores) when is_list(scores) do
    {score_a, score_b} =
      scores
      |> Enum.zip(problem_scores)
      |> Enum.reduce({0, 0}, fn {val, weight}, {sa, sb} ->
        case val do
          0 -> {sa, sb}
          x when x > 0 -> {sa + weight, sb}
          x when x < 0 -> {sa, sb + weight}
        end
      end)

    "#{score_a}:#{score_b}"
  end

  def mount(%{"id" => id, "round" => round_str}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(id)
    duels = CodeDuels.Tournaments.get_duels_for_tournament(id)

    duels_by_round =
      duels
      |> Enum.group_by(& &1.round_number)
      |> Map.to_list()
      |> Enum.sort_by(fn {round, _} -> round end)
      |> Map.new()

    available_rounds = Map.keys(duels_by_round)

    selected_round =
      if round_str, do: String.to_integer(round_str), else: List.first(available_rounds)

    {:ok,
     socket
     |> assign(:tournament, tournament)
     |> assign(:duels, duels)
     |> assign(:duels_by_round, duels_by_round)
     |> assign(:available_rounds, available_rounds)
     |> assign(:selected_round, selected_round)}
  end

  def mount(%{"id" => id}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(id)
    duels = CodeDuels.Tournaments.get_duels_for_tournament(id)

    duels_by_round =
      duels
      |> Enum.group_by(& &1.round_number)
      |> Map.to_list()
      |> Enum.sort_by(fn {round, _} -> round end)
      |> Map.new()

    available_rounds = Map.keys(duels_by_round)
    selected_round = List.first(available_rounds)

    {:ok,
     socket
     |> assign(:tournament, tournament)
     |> assign(:duels, duels)
     |> assign(:duels_by_round, duels_by_round)
     |> assign(:available_rounds, available_rounds)
     |> assign(:selected_round, selected_round)}
  end
end
