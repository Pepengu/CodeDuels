defmodule CodeDuelsWeb.ProblemLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    time_remaining =
      if assigns.round_unlock_time && assigns.now do
        diff = DateTime.diff(assigns.round_unlock_time, assigns.now)
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
            <.link navigate={"/#{@tournament_id}/#{@round_number}"} class="btn btn-ghost mb-4">
              &larr; К раунду
            </.link>

            <h1 class="text-4xl font-bold mb-2">Раунд {@round_number}</h1>
            <p class="text-lg text-base-content/70 mb-8">{@tournament.name}</p>

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

      assigns.problem == nil ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <div class="container mx-auto px-4 py-8">
            <.link navigate={"/#{@tournament_id}/#{@round_number}"} class="btn btn-ghost mb-4">
              &larr; К раунду
            </.link>

            <div class="card bg-base-200 shadow-xl">
              <div class="card-body text-center py-12">
                <h2 class="text-2xl font-bold">Задача {@problem_letter} не найдена</h2>
                <p class="text-lg opacity-70 mt-4">Эта задача недоступна в данный момент.</p>
              </div>
            </div>
          </div>
        </Layouts.app>
        """

      true ->
        ~H"""
        <Layouts.app flash={@flash} current_user={@current_user}>
          <div class="container mx-auto px-4 py-8">
            <.link navigate={"/#{@tournament_id}/#{@round_number}"} class="btn btn-ghost mb-4">
              &larr; К раунду
            </.link>

            <div class="mb-6">
              <.link navigate={"/#{@tournament_id}"} class="text-lg text-base-content/70 hover:underline">
                {@tournament.name}
              </.link>
              <span class="text-lg text-base-content/50 mx-2">&rsaquo;</span>
              <.link
                navigate={"/#{@tournament_id}/#{@round_number}"}
                class="text-lg text-base-content/70 hover:underline"
              >
                Раунд {@round_number}
              </.link>
              <span class="text-lg text-base-content/50 mx-2">&rsaquo;</span>
              <span class="text-lg font-semibold">Задача {@problem_letter}</span>
            </div>

            <div class="card bg-base-200 shadow-xl mb-6">
              <div class="card-body">
                <h1 class="text-3xl font-bold mb-4">{assigns.problem.title}</h1>

                <div class="flex flex-wrap gap-6 text-sm">
                  <div class="flex items-center gap-2">
                    <span class="font-semibold">Ограничение по времени:</span>
                    <span class="badge badge-primary">
                      {format_time_limit(assigns.problem.time_limit_ms)}
                    </span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-semibold">Ограничение по памяти:</span>
                    <span class="badge badge-secondary">
                      {format_memory_limit(assigns.problem.memory_limit_kb)}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div class="card bg-base-200 shadow-xl">
              <div class="card-body">
                <div class="problem-statement">
                  {raw(@statement_html)}
                </div>
              </div>
            </div>
          </div>
        </Layouts.app>
        """
    end
  end

  defp clean_problem_html(html) when is_binary(html) do
    doc = Floki.parse_document!(html)

    doc = Floki.filter_out(doc, "[class~='header']")

    cleaned_doc =
      Floki.traverse_and_update(doc, fn
        {"pre", attrs, children} = node ->
          if Enum.any?(attrs, fn {k, v} -> k == "class" && String.contains?(v, "content") end) do
            clean_text = extract_pre_content(attrs, children)
            {"pre", attrs, [clean_text]}
          else
            node
          end

        other ->
          other
      end)

    Floki.raw_html(cleaned_doc, encode: false)
  end

  defp extract_pre_content(attrs, children) do
    case Enum.find_value(attrs, fn
           {"data-content", v} -> v
           _ -> nil
         end) do
      nil ->
        test_lines = Floki.find(children, "[class*='test-example-line']")

        if test_lines != [] do
          test_lines
          |> Enum.map(&Floki.text/1)
          |> Enum.join("\n")
        else
          Floki.text(children)
        end

      text ->
        # Escape HTML special characters to avoid injection
        text
        |> String.replace("&", "&amp;")
        |> String.replace("<", "&lt;")
        |> String.replace(">", "&gt;")
    end
  end

  def mount(
        %{
          "tournament_id" => tournament_id,
          "round_number" => round_number,
          "letter" => letter
        },
        _session,
        socket
      ) do
    IO.inspect(socket)
    problem_letter = letter || ""
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round_num = String.to_integer(round_number)
    round = CodeDuels.Tournaments.get_round(tournament_id, round_num)

    letter_index = letter_to_index(problem_letter)

    problem_id =
      if round && round.problemset && letter_index >= 0 &&
           letter_index < length(round.problemset || []) do
        Enum.at(round.problemset, letter_index)
      else
        nil
      end

    problem = if problem_id, do: CodeDuels.Problems.get_problem!(problem_id), else: nil

    statement_html =
      with problem when not is_nil(problem) <- problem,
           path when is_binary(path) <- problem.statement,
           true <- File.exists?(path),
           {:ok, content} <- File.read(path) do
        # Clean the HTML (remove header, fix <pre> blocks) – no CSS injection
        clean_problem_html(content)
      else
        _ -> nil
      end

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    now = DateTime.utc_now()
    round_unlock_time = calculate_round_unlock_time(tournament, round_num, round)
    time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt
    locked = time_based_locked && !is_admin

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       round: round,
       problem: problem,
       problem_letter: String.upcase(problem_letter),
       statement_html: statement_html,
       locked: locked,
       round_unlock_time: round_unlock_time,
       now: now
     })}
  end

  defp letter_to_index(letter) do
    case letter |> String.upcase() |> String.to_charlist() |> hd() do
      c when c >= ?A and c <= ?Z -> c - ?A
      _ -> -1
    end
  end

  defp calculate_round_unlock_time(tournament, round_num, round) do
    if round && round.start_time && tournament.start_time do
      combine_datetime_with_time(tournament.start_time, round.start_time)
    else
      if tournament.start_time do
        offset_seconds =
          (round_num - 1) * (tournament.round_time || 0) +
            (round_num - 1) * (tournament.intermission_time || 0)

        DateTime.add(tournament.start_time, offset_seconds, :second)
      else
        nil
      end
    end
  end

  defp combine_datetime_with_time(datetime, time) do
    %{year: y, month: m, day: d} = datetime
    %{hour: h, minute: min, second: s} = time
    {:ok, dt} = NaiveDateTime.new(y, m, d, h, min, s)
    DateTime.from_naive!(dt, "Etc/UTC")
  end

  defp format_time(seconds) when seconds < 60, do: "#{seconds} сек"

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} мин #{remaining_seconds} сек"
  end

  defp format_time_limit(ms) when ms >= 1000, do: "#{div(ms, 1000)} сек"
  defp format_time_limit(ms), do: "#{ms} мс"

  defp format_memory_limit(kb) do
    mb = div(kb, 1024)

    if mb >= 1 and rem(kb, 1024) == 0 do
      "#{mb} МБ"
    else
      "#{kb} КБ"
    end
  end
end
