defmodule CodeDuelsWeb.TournamentDetailLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.Helpers.TimeHelpers

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
      <div class="container mx-auto px-4 py-8">
        <.tournament_header tournament={@tournament} active_tab="rounds" />

        <div class="flex flex-col lg:flex-row gap-50">
          <div class="w-full lg:w-1/2">
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <tbody>
                  <tr>
                    <td class="font-semibold">Время старта</td>
                    <td>{format_datetime_msk(@tournament.start_time)}</td>
                  </tr>
                  <tr>
                    <td class="font-semibold">Раунды</td>
                    <td>{@tournament.rounds_amount}</td>
                  </tr>
                  <tr>
                    <td class="font-semibold">Задач в раунде</td>
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
                  <tr>
                    <td class="font-semibold">Штраф</td>
                    <td>{@tournament.penalty}</td>
                  </tr>
                  <tr>
                    <td class="font-semibold">Макс. участников</td>
                    <td>{@tournament.max_participants}</td>
                  </tr>
                  <tr>
                    <td class="font-semibold">Статус</td>
                    <td>{if @tournament.is_open, do: "Открыт", else: "Закрыт"}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="w-full lg:w-1/3">
            <h2 class="text-xl font-semibold mb-4">Раунды</h2>
            <div class="flex flex-col gap-3">
              <%= for round <- 1..(@tournament.rounds_amount || 0) do %>
                {render_round_card(assigns, round)}
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp render_round_card(assigns, round) do
    tournament = assigns.tournament
    current_user = assigns.current_user
    ppr = tournament.problems_per_round || 0

    start_idx = (round - 1) * ppr
    end_idx = start_idx + ppr - 1

    round_scores =
      if tournament.scores,
        do: Enum.slice(tournament.scores, start_idx..end_idx) |> Enum.sum(),
        else: nil

    is_admin = current_user && current_user.is_admin
    now = assigns.now || DateTime.utc_now()
    round_unlock_time = CodeDuels.Tournaments.round_unlock_time(tournament, round)

    is_unlocked_by_time =
      is_nil(round_unlock_time) ||
        DateTime.compare(now, round_unlock_time) in [:gt, :eq]

    assigns = assign(assigns, :round_number, round)
    assigns = assign(assigns, :ppr, ppr)
    assigns = assign(assigns, :round_scores, round_scores || "-")

    cond do
      is_unlocked_by_time ->
        ~H"""
        <.link
          navigate={"/tournament/#{@tournament.id}/#{@round_number}"}
          class="card bg-base-200 hover:bg-base-300 shadow-md hover:shadow-lg transition-all"
        >
          <div class="card-body flex flex-row items-center justify-between py-3">
            <div class="flex flex-col">
              <span class="font-semibold text-lg">Раунд {@round_number}</span>
              <span class="text-xs opacity-70">
                {@ppr} задач · {@round_scores} очк
              </span>
            </div>
            <span class="text-xl">&rarr;</span>
          </div>
        </.link>
        """

      is_admin ->
        remaining = DateTime.diff(round_unlock_time, now)
        assigns = assign(assigns, :remaining, remaining)

        ~H"""
        <.link
          navigate={"/tournament/#{@tournament.id}/#{@round_number}"}
          class="card bg-base-300 shadow-md opacity-70 hover:opacity-90"
        >
          <div class="card-body flex flex-row items-center justify-between py-3">
            <div class="flex flex-col">
              <span class="font-semibold text-lg">Раунд {@round_number}</span>
              <span class="text-xs opacity-70">Начнётся через {format_time(@remaining)}</span>
            </div>
            <span class="text-xl">🔒</span>
          </div>
        </.link>
        """

      true ->
        remaining = DateTime.diff(round_unlock_time, now)
        assigns = assign(assigns, :remaining, remaining)

        ~H"""
        <div class="card bg-base-300 shadow-md opacity-70">
          <div class="card-body flex flex-row items-center justify-between py-3">
            <div class="flex flex-col">
              <span class="font-semibold text-lg">Раунд {@round_number}</span>
              <span class="text-xs opacity-70">Начнётся через {format_time(@remaining)}</span>
            </div>
            <span class="text-xl">🔒</span>
          </div>
        </div>
        """
    end
  end

  defp format_datetime_msk(nil), do: "Не задано"

  defp format_datetime_msk(datetime) do
    msk_time = DateTime.add(datetime, 3 * 3600, :second)
    Calendar.strftime(msk_time, "%Y-%m-%d %H:%M MSK")
  end

  def mount(%{"id" => id}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(id)
    schedule_timer()
    socket = assign(socket, :tournament, tournament)
    socket = assign(socket, :now, DateTime.utc_now())
    {:ok, socket}
  end

  def handle_info(:tick, socket) do
    schedule_timer()
    now = DateTime.utc_now()
    previous_now = socket.assigns[:now] || now
    tournament = socket.assigns.tournament
    current_user = socket.assigns.current_user
    is_admin = current_user && current_user.is_admin

    newly_unlocked =
      for round <- 1..(tournament.rounds_amount || 0),
          round_unlock_time = CodeDuels.Tournaments.round_unlock_time(tournament, round),
          round_unlock_time,
          reduce: nil do
        acc ->
          was_locked = DateTime.compare(previous_now, round_unlock_time) == :lt
          is_unlocked = DateTime.compare(now, round_unlock_time) != :lt

          if was_locked && is_unlocked && !is_admin do
            round
          else
            acc
          end
      end

    socket =
      if newly_unlocked do
        send_update(CodeDuelsWeb.RoundNotificationPopup,
          id: "round-notification",
          action: :show,
          title: "Раунд начался!",
          message: "Раунд #{newly_unlocked} доступен!"
        )

        socket
      else
        socket
      end

    {:noreply, assign(socket, :now, now)}
  end
end
