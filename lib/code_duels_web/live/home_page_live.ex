defmodule CodeDuelsWeb.HomePageLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px bg-secondary rounded-box my-8">

        <!-- Hero Section -->
        <div class="hero bg-gradient-to-b from-primary to-secondary text-primary-content rounded-box">
          <div class="hero-content text-center py-20">
            <div class="max-w-2xl">
              <h1 class="text-5xl font-extrabold mb-4">Code. Compete. Conquer.</h1>
              <p class="text-xl mb-8">
                Join real-time coding duels, challenge friends, and climb the leaderboard.
              </p>
              <div class="flex justify-center gap-4">
                <button
                  phx-click="show_popup" 
                  phx-value-title="⚔️ Duel Feature Coming Soon"
                  phx-value-message="1v1 coding battles are still being worked on"

                  class="btn btn-primary bg-white text-primary border-white hover:bg-gray-100 hover:border-white"
                >
                  Start a Duel
                </button>
                <button
                  phx-click="show_popup"
                  phx-value-title="🏆 Tournament feature coming soon"
                  phx-value-message="Code duel tournaments are still being worked on"

                  class="btn btn-outline btn-primary border-white text-white hover:bg-white hover:text-primary"
                >
                  Browse Tournaments
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Featured Tournaments -->
        <section class="container mx-auto px-4 py-16">
          <h2 class="text-3xl font-bold text-center mb-12">🔥 Live Tournaments</h2>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body">
                <div class="flex justify-between items-center mb-2">
                  <span class="badge badge-success gap-2">Open</span>
                  <span class="text-sm opacity-70">⏱️ 2h left</span>
                </div>
                <h3 class="card-title">Weekend Warzone</h3>
                <p class="opacity-70">Python • 1v1 • Best of 3</p>
                <div class="card-actions justify-between items-center mt-4">
                  <span class="text-sm">32 players</span>
                  <a class="link link-primary">Join →</a>
                </div>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body">
                <div class="flex justify-between items-center mb-2">
                  <span class="badge badge-warning gap-2">Starting soon</span>
                  <span class="text-sm opacity-70">⏱️ 15 min</span>
                </div>
                <h3 class="card-title">Algorithms Rush</h3>
                <p class="opacity-70">JavaScript • 3+ players • FFA</p>
                <div class="card-actions justify-between items-center mt-4">
                  <span class="text-sm">18 players</span>
                  <a class="link link-primary">Join →</a>
                </div>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body">
                <div class="flex justify-between items-center mb-2">
                  <span class="badge badge-secondary gap-2">Qualifiers</span>
                  <span class="text-sm opacity-70">⏱️ 3d left</span>
                </div>
                <h3 class="card-title">Pro League Season 5</h3>
                <p class="opacity-70">Any language • Team • Elimination</p>
                <div class="card-actions justify-between items-center mt-4">
                  <span class="text-sm">64 players</span>
                  <a class="link link-primary">Join →</a>
                </div>
              </div>
            </div>
          </div>
          <div class="text-center mt-10">
            <a class="link link-primary-content font-semibold">View all tournaments →</a>
          </div>
        </section>

        <!-- How It Works -->
        <section class="container mx-auto px-4 py-16">
          <h2 class="text-3xl font-bold text-center mb-12">How Code Duels Work</h2>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-16 mx-16">
            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body text-center">
                <div class="bg-primary/20 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" />
                  </svg>
                </div>
                <h3 class="text-xl font-semibold mb-2">1. Choose a Duel</h3>
                <p class="text-base-content/70">Pick a tournament or challenge a friend in real-time.</p>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body text-center">
                <div class="bg-primary/20 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                  </svg>
                </div>
                <h3 class="text-xl font-semibold mb-2">2. Code Head-to-Head</h3>
                <p class="text-base-content/70">Solve the same problem faster and cleaner than your opponent.</p>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md hover:shadow-lg transition">
              <div class="card-body text-center">
                <div class="bg-primary/20 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 class="text-xl font-semibold mb-2">3. Earn Glory</h3>
                <p class="text-base-content/70">Win points, climb ranks, and unlock achievements.</p>
              </div>
            </div>
          </div>
          <div class="text-center mt-10">
            <a class="link link-primary-content font-semibold">View all tournaments →</a>
          </div>
        </section>

        <!-- Leaderboard Preview -->
        <section class="container mx-auto px-4 py-16">
          <h2 class="text-3xl font-bold text-center mb-12">🏆 Top Coders</h2>
          <div class="max-w-2xl mx-auto card bg-base-100 shadow-md">
            <div class="divide-y">
              <div class="flex items-center p-4">
                <span class="text-2xl font-bold text-base-content/30 w-8">1</span>
                <div class="flex-1 ml-4">
                  <p class="font-semibold">alex_coder</p>
                  <p class="text-sm opacity-70">Python • 2540 pts</p>
                </div>
                <span class="badge badge-primary gap-1">🔥 12 win streak</span>
              </div>
              <div class="flex items-center p-4">
                <span class="text-2xl font-bold text-base-content/30 w-8">2</span>
                <div class="flex-1 ml-4">
                  <p class="font-semibold">byte_battler</p>
                  <p class="text-sm opacity-70">JavaScript • 2410 pts</p>
                </div>
                <span class="badge badge-primary gap-1">⚡ 8 win streak</span>
              </div>
              <div class="flex items-center p-4">
                <span class="text-2xl font-bold text-base-content/30 w-8">3</span>
                <div class="flex-1 ml-4">
                  <p class="font-semibold">rustacean</p>
                  <p class="text-sm opacity-70">Rust • 2380 pts</p>
                </div>
                <span class="badge badge-primary gap-1">🚀 5 win streak</span>
              </div>
            </div>
          </div>
          <div class="text-center mt-6">
            <a class="link link-primary-content font-semibold">Full leaderboard →</a>
          </div>
        </section>

        <.live_component
          module={CodeDuelsWeb.ComingSoonPopup}
          id="coming-soon"
        />
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("show_popup", %{"title" => title, "message" => message}, socket) do
    send_update(CodeDuelsWeb.ComingSoonPopup,
      id: "coming-soon",
      action: :show,
      title: title,
      message: message
    )
    {:noreply, socket}
  end

  def handle_info(:close_popup, socket) do
    send_update(CodeDuelsWeb.ComingSoonPopup,
      id: "coming-soon",
      action: :hide
    )

    {:noreply, socket}
  end

  def handle_info(:show_popup, socket) do
    send_update(CodeDuelsWeb.ComingSoonPopup,
      id: "coming-soon",
      action: :show
    )

    {:noreply, socket}
  end
end
