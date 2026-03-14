defmodule CodeDuelsWeb.ComingSoonPopup do
  use CodeDuelsWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, show: false)}
  end

  def render(assigns) do
    ~H"""
    <div
      class={[
        "fixed top-4 left-1/2 -translate-x-1/2 z-50 w-96 max-w-[90%]",
        "bg-primary text-primary-content shadow-lg rounded-lg p-4",
        "flex items-start gap-3 transition-all duration-300 ease-out",
        @show && "opacity-100 translate-y-0 pointer-events-auto",
        !@show && "opacity-0 -translate-y-4 pointer-events-none"
      ]}
      role="alert"
    >
      <div class="flex-1">
        <h3 class="font-bold text-lg"><%= @title %></h3>
        <p class="text-sm opacity-90"><%= @message %></p>
      </div>
      <button
        phx-click="close"
        phx-target={@myself}
        class="text-primary-content hover:text-white opacity-70 hover:opacity-100"
        aria-label="close"
      >
        <span class="text-2xl leading-none">×</span>
      </button>
    </div>
    """
  end

  def update(%{action: :show} = assigns, socket) do
    if timer = socket.assigns[:timer] do
      Process.cancel_timer(timer)
    end

    timer = Process.send_after(self(), :close_popup, 3000)
    title = assigns[:title] || "Coming Soon"
    message = assigns[:message] || "This feature is under development. Stay tuned!"

    socket = assign(socket, show: true, timer: timer, title: title, message: message)
    
    {:ok, socket}
  end

  def update(%{action: :hide}, socket) do
    {:ok, assign(socket, show: false)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(
       title: assigns[:title] || socket.assigns[:title] || "Coming Soon",
       message: assigns[:message] || socket.assigns[:message] || "This feature is under development. Stay tuned!"
     )}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, show: false)}
  end
end
