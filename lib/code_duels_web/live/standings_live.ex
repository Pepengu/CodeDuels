defmodule CodeDuelsWeb.StandingsLive do
  use CodeDuelsWeb, :live_view

  on_mount {CodeDuelsWeb.LiveAuth, :default}

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <.tournament_header tournament={@tournament} active_tab="standings" />

        <div class="flex justify-center">
          <table class="table table-zebra table-fixed w-auto">
            <thead>
              <tr>
                <th class="text-center w-12">#</th>
                <th class="w-32">Игрок</th>
                <th class="text-center w-16">Очки</th>
                <th class="text-center w-16">Очки тура</th>
                <th class="text-center w-16">Штраф</th>
                <th class="text-center w-16">Победы</th>
                <th class="text-center w-16">Ничьи</th>
                <th class="text-center w-16">Поражения</th>
                <%= for round_num <- 1..@tournament.rounds do %>
                  <th class="text-center w-12">R{round_num}</th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for entry <- @standings do %>
                <tr class={
                  if @current_user && entry.user_id == @current_user.id,
                    do: "ring ring-yellow-500 hover",
                    else: "hover"
                }>
                  <td class="text-center font-semibold">
                    {case entry.rank do
                      1 -> "🥇"
                      2 -> "🥈"
                      3 -> "🥉"
                      _ -> entry.rank
                    end}
                  </td>
                  <td class="font-medium">{entry.name}</td>
                  <td class="text-center font-bold">{Float.round(entry.score, 1)}</td>
                  <td class="text-center">{entry.tournament_points}</td>
                  <td class="text-center">{entry.total_penalty}</td>
                  <td class="text-center text-green-600">{entry.wins}</td>
                  <td class="text-center text-yellow-600">{entry.draws}</td>
                  <td class="text-center text-red-600">{entry.losses}</td>
                  <%= for round_num <- 1..@tournament.rounds do %>
                    <% round_data = Enum.at(entry.round_results, round_num - 1) %>
                    <td class={result_class(round_data)}>
                      <div class="font-bold">{elem(round_data, 0)}</div>
                      <div class="text-xs text-gray-400">{elem(round_data, 1)}</div>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <%= if Enum.empty?(@standings) do %>
          <div class="text-center py-12 text-lg opacity-70">
            Участники пока не зарегистрированы
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(id)
    standings = CodeDuels.Tournaments.get_standings_with_stats(id)

    {:ok, assign(socket, tournament: tournament, standings: standings)}
  end

  defp result_class(round_data) do
    result = elem(round_data, 0)

    case result do
      "1" -> "text-center font-bold text-green-600"
      "0.5" -> "text-center font-bold text-yellow-600"
      "0" -> "text-center font-bold text-red-600"
      _ -> "text-center text-gray-400"
    end
  end
end
