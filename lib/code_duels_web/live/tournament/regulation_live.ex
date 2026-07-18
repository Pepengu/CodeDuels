defmodule CodeDuelsWeb.RegulationLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <.tournament_header tournament={@tournament} active_tab="regulation" />

        <div class="flex justify-end mb-6">
          <a href={~p"/tournament/#{@tournament.id}/regulation.pdf"} class="btn btn-primary gap-2">
            <.icon name="hero-arrow-down-tray" class="w-5 h-5" /> Скачать PDF
          </a>
        </div>

        <div :if={@regulations_html} class="typst-content bg-base-100 rounded-box p-8 shadow-sm">
          {raw(@regulations_html)}
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    case Integer.parse(id) do
      {int_id, ""} when int_id > 0 ->
        tournament = CodeDuels.Tournaments.get_tournament!(int_id)

        socket =
          socket
          |> assign(:tournament, tournament)

        socket =
          case read_cached_html(tournament.id) do
            {:ok, html} ->
              assign(socket, :regulations_html, HtmlSanitizeEx.html5(html))

            {:error, _} ->
              socket
              |> assign(:regulations_html, nil)
              |> put_flash(:error, "Положение пока не сгенерировано.")
          end

        {:ok, socket}

      _ ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  defp read_cached_html(tournament_id) do
    path = Path.join(CodeDuels.Typst.cache_dir(tournament_id), "regulations.html")

    case File.read(path) do
      {:ok, html} -> {:ok, html}
      {:error, _} -> {:error, :not_found}
    end
  end
end
