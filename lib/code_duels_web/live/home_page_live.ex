defmodule CodeDuelsWeb.HomePageLive do
alias Phoenix.Debug
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
      <div class="container mx-auto px bg-secondary rounded-box my-8">
        <.live_component
          module={CodeDuelsWeb.ComingSoonPopup}
          id="coming-soon"
        />
      </div>
    """
  end

  def mount(_params, session, socket) do
    if Map.get(session, "user_id") == nil do
      #socket |> redirect("/login")
    end
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
