defmodule CodeDuelsWeb.TournamentPageLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-4xl font-bold mb-8">Открытые турниры</h1>

        <div :if={@tournaments == []} class="text-center py-12">
          <p class="text-xl opacity-60">Нет доступных турниров.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div :for={tournament <- @tournaments} class="card bg-base-200 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-2xl">{tournament.name}</h2>

              <div class="space-y-2 mt-4">
                <div class="flex justify-between">
                  <span class="opacity-60">Раунды:</span>
                  <span class="font-semibold">{tournament.rounds}</span>
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

              <div class="card-actions justify-end mt-6">
                <.link navigate={"/#{tournament.id}"} class="btn btn-primary">Подробнее</.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    tournaments = CodeDuels.Tournaments.list_open_tournaments()
    {:ok, assign(socket, :tournaments, tournaments)}
  end
end
