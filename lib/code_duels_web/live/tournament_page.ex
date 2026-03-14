defmodule CodeDuelsWeb.TournamentPageLive do
  use CodeDuelsWeb, :live_view


  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex items-start justify-center pt-40 bg-base-100">
        <div class="text-center">
          <h1 class="text-6xl font-bold mb-4">Code Duels</h1>
          <div class="badge badge-primary badge-lg gap-2 text-2xl py-6 px-8">
            Under Construction
          </div>
          <p class="text-sm opacity-60 mt-4">
            Coming soon
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
