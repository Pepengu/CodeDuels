defmodule CodeDuelsWeb.RoundDetailLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.Helpers.TimeHelpers

  def render(assigns) do
    cond do
      assigns.locked ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
          <div class="container mx-auto px-4 py-8">
            <.round_header tournament={@tournament} round_number={@round_number} active_tab="problems" />

            <div class="card bg-base-200 shadow-xl">
              <div class="card-body text-center py-12">
                <h2 class="text-2xl font-bold">Раунд ещё не начался</h2>
                <p class="text-3xl font-bold text-primary mt-4">{@time_remaining}</p>
              </div>
            </div>
          </div>
        </Layouts.app>
        """

      assigns.time_based_locked ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
          <div class="container mx-auto px-4 py-8">
            <.round_header tournament={@tournament} round_number={@round_number} active_tab="problems" />

            <span class="alert alert-warning mb-6">{@time_remaining}</span>

            <div class="grid gap-6 lg:grid-cols-3">
              <div class="lg:col-span-2">
                <h2 class="text-xl font-semibold mb-4">Задачи</h2>
                <div class="flex flex-col gap-4">
                  <%= for {problem, idx} <- Enum.with_index(@problems) do %>
                    <div class="card bg-base-200 shadow-md">
                      <div class="card-body">
                        <div class="flex flex-row items-center justify-between">
                          <h3 class="font-semibold">{problem.title}</h3>
                          <span class="badge badge-lg">{problem.letter}</span>
                        </div>
                        <p class="text-sm opacity-70 mt-2">{problem.description}</p>
                        <div class="mt-3 flex flex-row items-center justify-between">
                          <span class="font-semibold">{Enum.at(@round_scores, idx, "-")} очк</span>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

              <div>
                <div class="card bg-base-200 shadow-xl">
                  <div class="card-body">
                    <h2 class="card-title">Статистика</h2>
                    <div class="overflow-x-auto">
                      <table class="table table-zebra">
                        <tbody>
                          <tr>
                            <td class="font-semibold">Всего очков</td>
                            <td>{@total_score} очк</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Задач</td>
                            <td>{@tournament.problems_per_round}</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Время раунда</td>
                            <td>{@tournament.round_time} сек</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Перерыв</td>
                            <td>{@tournament.intermission_time} сек</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>

                <div class="card bg-base-200 shadow-xl mt-6">
                  <div class="card-body">
                    <.link
                      navigate={~p"/#{@tournament_id}/#{@round_number}/submit"}
                      class="btn btn-primary btn-block"
                    >
                      Отправить решение
                    </.link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Layouts.app>
        """

      true ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
          <div class="container mx-auto px-4 py-8">
            <.round_header tournament={@tournament} round_number={@round_number} active_tab="problems" />

            <div class="grid gap-6 lg:grid-cols-3">
              <div class="lg:col-span-2">
                <h2 class="text-xl font-semibold mb-4">Задачи</h2>
                <div class="flex flex-col gap-4">
                  <%= for {problem, idx} <- Enum.with_index(@problems) do %>
                    <.link
                      navigate={~p"/#{@tournament_id}/#{@round_number}/problem?letter=#{<<idx + ?A>>}"}
                      class="block"
                    >
                      <div class="card bg-base-200 shadow-md hover:shadow-lg transition-shadow cursor-pointer">
                        <div class="card-body">
                          <div class="flex flex-row items-center justify-between">
                            <h3 class="font-semibold">{problem.title}</h3>
                            <span class="badge badge-lg">{problem.letter}</span>
                          </div>
                          <p class="text-sm opacity-70 mt-2">{problem.description}</p>
                          <div class="mt-3 flex flex-row items-center justify-between">
                            <span class="font-semibold">{Enum.at(@round_scores, idx, "-")} очк</span>
                          </div>
                        </div>
                      </div>
                    </.link>
                  <% end %>
                </div>
              </div>

              <div>
                <div class="card bg-base-200 shadow-xl">
                  <div class="card-body">
                    <h2 class="card-title">Статистика</h2>
                    <div class="overflow-x-auto">
                      <table class="table table-zebra">
                        <tbody>
                          <tr>
                            <td class="font-semibold">Всего очков</td>
                            <td>{@total_score} очк</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Задач</td>
                            <td>{@tournament.problems_per_round}</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Время раунда</td>
                            <td>{@tournament.round_time} сек</td>
                          </tr>
                          <tr>
                            <td class="font-semibold">Перерыв</td>
                            <td>{@tournament.intermission_time} сек</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>

                <div class="card bg-base-200 shadow-xl mt-6">
                  <div class="card-body">
                    <.link
                      navigate={~p"/#{@tournament_id}/#{@round_number}/submit"}
                      class="btn btn-primary btn-block"
                    >
                      Отправить решение
                    </.link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Layouts.app>
        """
    end
  end

  def mount(%{"tournament_id" => tournament_id, "round_number" => round_number}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round = CodeDuels.Tournaments.get_round(tournament_id, round_number)
    problemset = CodeDuels.Tournaments.get_problemset(round.problemset)
    round_num = String.to_integer(round_number)

    ppr = tournament.problems_per_round || 3
    start_idx = (round_num - 1) * ppr

    round_scores =
      if tournament.scores,
        do: Enum.slice(tournament.scores, start_idx, ppr),
        else: List.duplicate(nil, ppr)

    total_score = Enum.reject(round_scores, &is_nil/1) |> Enum.sum()

    {problems, _} =
      problemset
      |> Enum.map_reduce(?A, fn problem, acc ->
        {
          %{
            title: problem.title,
            letter: <<acc>>,
            description: "Решите эту задачу за отведённое время."
          },
          acc + 1
        }
      end)

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    round_state = CodeDuels.Tournaments.RoundState.compute(tournament, round_num, is_admin)

    schedule_timer()

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       problems: problems,
       round_scores: round_scores,
       total_score: total_score,
       locked: round_state.locked,
       time_based_locked: round_state.time_based_locked,
       time_remaining: round_state.time_remaining,
       round_unlock_time: round_state.round_unlock_time,
       now: round_state.now
     })}
  end

  def handle_info(:tick, socket) do
    schedule_timer()
    was_time_based_locked = socket.assigns[:time_based_locked]
    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin

    round_state =
      CodeDuels.Tournaments.RoundState.compute(
        socket.assigns.tournament,
        socket.assigns.round_number,
        is_admin
      )

    socket =
      assign(socket,
        now: round_state.now,
        locked: round_state.locked,
        time_based_locked: round_state.time_based_locked,
        time_remaining: round_state.time_remaining
      )

    socket =
      if was_time_based_locked && !round_state.time_based_locked do
        send_update(CodeDuelsWeb.RoundNotificationPopup,
          id: "round-notification",
          action: :show,
          title: "Раунд начался!",
          message: "Раунд #{socket.assigns.round_number} доступен!"
        )

        socket
      else
        socket
      end

    {:noreply, socket}
  end
end
