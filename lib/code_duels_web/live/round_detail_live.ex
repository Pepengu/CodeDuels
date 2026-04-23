defmodule CodeDuelsWeb.RoundDetailLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    time_remaining =
      if @round_unlock_time && @now do
        diff = DateTime.diff(@round_unlock_time, @now)
        if diff > 0, do: format_time(diff), else: "0 сек"
      else
        ""
      end

    cond do
      @locked ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
          <div class="container mx-auto px-4 py-8">
            <.round_header tournament={@tournament} round_number={@round_number} active_tab="problems" />

            <div class="card bg-base-200 shadow-xl">
              <div class="card-body text-center py-12">
                <h2 class="text-2xl font-bold">Раунд ещё не начался</h2>
                <p class="text-lg opacity-70 mt-4">До начала осталось</p>
                <p class="text-3xl font-bold text-primary mt-2">{time_remaining}</p>
              </div>
            </div>
          </div>
        </Layouts.app>
        """

      @time_based_locked ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
          <div class="container mx-auto px-4 py-8">
            <.round_header tournament={@tournament} round_number={@round_number} active_tab="problems" />

            <div class="alert alert-warning mb-6">
              <span>Раунд начнётся через: <strong>{time_remaining}</strong></span>
            </div>

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
    IO.inspect(problemset)
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
    now = DateTime.utc_now()
    round_unlock_time = calculate_round_unlock_time(tournament, round_num)
    time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt
    locked = time_based_locked && !is_admin

    schedule_timer()

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       problems: problems,
       round_scores: round_scores,
       total_score: total_score,
       locked: locked,
       time_based_locked: time_based_locked,
       round_unlock_time: round_unlock_time,
       now: now
     })}
  end

  defp calculate_round_unlock_time(tournament, round) do
    if tournament.start_time do
      offset_seconds =
        (round - 1) * tournament.round_time + (round - 1) * tournament.intermission_time

      DateTime.add(tournament.start_time, offset_seconds, :second)
    else
      nil
    end
  end

  defp format_time(seconds) when seconds < 60, do: "#{seconds} сек"

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} мин #{remaining_seconds} сек"
  end

  def handle_info(:tick, socket) do
    schedule_timer()
    now = DateTime.utc_now()
    was_time_based_locked = socket.assigns[:time_based_locked]
    round_unlock_time = socket.assigns[:round_unlock_time]
    is_time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    locked = is_time_based_locked && !is_admin

    socket = assign(socket, now: now, locked: locked, time_based_locked: is_time_based_locked)

    socket =
      if was_time_based_locked && !is_time_based_locked do
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

  defp schedule_timer do
    Process.send_after(self(), :tick, 1000)
  end
end
