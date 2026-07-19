defmodule CodeDuelsWeb.TournamentPageLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-4xl font-bold mb-8">Турниры</h1>

        <div :if={@tournaments == []} class="text-center py-12">
          <p class="text-xl opacity-60">Нет доступных турниров.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div :for={tournament <- @tournaments} class="card bg-base-200 shadow-lg">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <h2 class="card-title text-2xl">{tournament.name}</h2>
                <span class={[
                  "badge badge-sm",
                  tournament.status == "setup" && "badge-info",
                  tournament.status == "in_progress" && "badge-success",
                  tournament.status == "completed" && "badge-ghost"
                ]}>
                  <%= cond do %>
                    <% tournament.status == "setup" -> %>
                      Скоро
                    <% tournament.status == "in_progress" -> %>
                      Идёт
                    <% tournament.status == "completed" -> %>
                      Завершён
                    <% true -> %>
                      {tournament.status}
                  <% end %>
                </span>
              </div>

              <div class="space-y-2 mt-4">
                <div class="flex justify-between">
                  <span class="opacity-60">Раунды:</span>
                  <span class="font-semibold">{tournament.rounds_amount}</span>
                </div>
                <div class="flex justify-between">
                  <span class="opacity-60">Время раунда:</span>
                  <span class="font-semibold">{tournament.round_time} сек</span>
                </div>
                <div class="flex justify-between">
                  <span class="opacity-60">Участники:</span>
                  <span class="font-semibold">{tournament.max_participants}</span>
                </div>
              </div>

              <div class="flex items-center w-full mt-6">
                <div class="flex-1 flex justify-start">
                  <%= if tournament.status != "completed" do %>
                    <.link
                      navigate={"/tournament/#{tournament.id}/registration"}
                      class="btn btn-primary"
                    >
                      Регистрация
                    </.link>
                  <% end %>
                </div>

                <div class="flex-1 flex justify-center">
                  <.link
                    navigate={"/tournament/#{tournament.id}/regulation"}
                    class="btn btn-primary"
                  >
                    Положение
                  </.link>
                </div>

                <div class="flex-1 flex justify-end">
                  <.link navigate={"/tournament/#{tournament.id}"} class="btn btn-primary">
                    Подробнее
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    tournaments = CodeDuels.Tournaments.list_tournaments_for_user(socket.assigns.current_user)
    {:ok, assign(socket, :tournaments, tournaments)}
  end
end
