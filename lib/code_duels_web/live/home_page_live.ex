defmodule CodeDuelsWeb.HomePageLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}></Layouts.app>
    """
  end

  def mount(_params, session, socket) do
    if Map.get(session, "user_id") == nil do
      # socket |> redirect("/login")
    end

    {:ok, socket}
  end

  def handle_event("show_popup", %{"title" => title, "message" => message}, socket) do
    {:noreply, socket}
  end

  def handle_info(:close_popup, socket) do
    {:noreply, socket}
  end

  def handle_info(:show_popup, socket) do
    {:noreply, socket}
  end
end
