defmodule CodeDuelsWeb.ProblemLive do
  use CodeDuelsWeb, :live_view

  def render(assigns) do
    cond do
      assigns.locked ->
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
                <p
                  id="locked-timer"
                  class="text-3xl font-bold text-primary mt-2"
                  phx-hook="CountdownHook"
                  data-unlock={@unlock_ts}
                  data-end={@end_ts}
                >
                  {@time_remaining}
                </p>
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

            <div class="grid grid-cols-[5fr_1fr] gap-2">
              <div>
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
                    <div class="problem-statement" , id="problem-statement" , phx-hook="MathJaxHook">
                      {raw(@statement_html)}
                    </div>
                  </div>
                </div>
              </div>
              <div class="card bg-base-200 shadow-xl">
                <div class="card-body p-4">
                  {sidebar_timer(assigns)}
                  {sidebar_problem_list(assigns)}
                  {sidebar_duel(assigns)}
                  {sidebar_submit_button(assigns)}
                  {sidebar_previous_submissions(assigns)}
                </div>
              </div>
            </div>
          </div>
        </Layouts.app>
        """
    end
  end

  defp sidebar_timer(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl mt-4">
      <div class="card-body p-4 flex flex-col items-center">
        <span class="font-semibold text-center">Время до завершения раунда</span>
        <span
          id="active-timer"
          class="mt-1 badge badge-primary text-sm"
          phx-hook="CountdownHook"
          data-unlock={@unlock_ts}
          data-end={@end_ts}
        >
          {@time_remaining}
        </span>
      </div>
    </div>
    """
  end

  defp sidebar_problem_list(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body p-4">
        <h3 class="font-semibold mb-2 text-center">Задачи раунда</h3>
        <div class="space-y-1">
          <%= for problem <- @problems do %>
            <.link
              navigate={"/#{@tournament_id}/#{@round_number}/problem?letter=#{problem.letter}"}
              class={[
                "block px-3 py-2 rounded-lg transition-colors",
                if(problem.letter == @problem_letter,
                  do: "bg-secondary text-secondary-content",
                  else: "hover:bg-base-300"
                )
              ]}
            >
              <span class="font-semibold">{problem.letter}</span> — {problem.title}
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_duel(assigns) do
    ~H"""
    <%= if @duel_a_name do %>
      <div class="card bg-base-200 shadow-xl mt-4">
        <div class="card-body p-4">
          <div class="text-center mb-2">
            <span class={[
              "font-semibold text-blue-500",
              if(@duel_is_user_a, do: "bg-yellow-500/10 px-1 rounded")
            ]}>
              {@duel_a_name}
            </span>
            <span class="opacity-50 mx-1">vs</span>
            <span class={[
              "font-semibold text-red-500",
              if(!@duel_is_user_a, do: "bg-yellow-500/10 px-1 rounded")
            ]}>
              {@duel_b_name}
            </span>
          </div>
          <hr class="opacity-20 my-2" />
          <div class="space-y-1">
            <div class="flex justify-between text-sm">
              <span class="font-semibold">Счёт</span>
              <span class="font-bold">{@duel_a_score} — {@duel_b_score}</span>
            </div>
            <%= for dp <- @duel_problems do %>
              <div class="flex justify-between text-sm">
                <span class="font-semibold">Задача {dp.letter}</span>
                <span class={duel_problem_class(dp.winner)}>{dp.points}</span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp sidebar_submit_button(assigns) do
    ~H"""
    <.link
      navigate={"/#{@tournament_id}/#{@round_number}/submit?letter=#{@problem_letter}"}
      class="btn btn-secondary btn-block mt-4"
    >
      <span class="font-semibold text-center">Отправить решение</span>
    </.link>
    """
  end

  defp sidebar_previous_submissions(assigns) do
    ~H"""
    <%= if @submissions != [] do %>
      <.submissions_table
        title="Предыдущие попытки"
        submissions={@submissions}
        tournament_id={@tournament_id}
        round_number={@round_number}
        show_problem?={false}
      />
    <% end %>
    """
  end

  defp clean_problem_html(html) when is_binary(html) do
    doc =
      Floki.parse_document!(html)
      |> Floki.filter_out("[class~='header']")
      |> Floki.filter_out("link")

    Floki.raw_html(doc, encode: false)
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

    problemset = if round, do: CodeDuels.Tournaments.get_problemset(round.problemset), else: []

    problems =
      problemset
      |> Enum.map_reduce(?A, fn problem, acc ->
        {%{
           id: problem.id,
           title: problem.title,
           letter: <<acc>>
         }, acc + 1}
      end)
      |> elem(0)

    statement_html =
      with problem when not is_nil(problem) <- problem,
           path when is_binary(path) <- problem.statement,
           true <- File.exists?(path),
           {:ok, content} <- File.read(path) do
        clean_problem_html(content)
      else
        _ -> nil
      end

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    now = DateTime.utc_now()
    round_unlock_time = CodeDuels.Tournaments.round_unlock_time(tournament, round_num)

    round_end_time =
      if round_unlock_time,
        do: DateTime.add(round_unlock_time, tournament.round_time, :second),
        else: nil

    time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt
    locked = time_based_locked && !is_admin

    time_remaining = calculate_time_remaining(now, round_end_time, round_unlock_time)

    unlock_ts = round_unlock_time && DateTime.to_unix(round_unlock_time)
    end_ts = round_end_time && DateTime.to_unix(round_end_time)

    submissions =
      CodeDuels.Tournaments.get_all_user_submissions(
        socket.assigns.current_user.id,
        round.id,
        letter
      )

    {duel_a_name, duel_b_name, duel_is_user_a, duel_a_score, duel_b_score, duel_problems} =
      if socket.assigns[:current_user] && round do
        duel =
          CodeDuels.Tournaments.get_duel_for_user(
            tournament_id,
            round_num,
            socket.assigns[:current_user].id
          )

        if duel do
          is_player_a = duel.player_a.user_id == socket.assigns[:current_user].id

          a_name = duel.player_a.user.username || duel.player_a.user.name || "Player A"
          b_name = duel.player_b.user.username || duel.player_b.user.name || "Player B"

          ppr = tournament.problems_per_round || 3
          start_idx = (round_num - 1) * ppr

          problem_points =
            if tournament.scores,
              do: Enum.slice(tournament.scores, start_idx, ppr),
              else: List.duplicate(1, ppr)

          problem_ids = problemset |> Enum.map(& &1.id)

          subs_data =
            CodeDuels.Tournaments.get_submissions_for_participants(
              [duel.player_a.user_id, duel.player_b.user_id],
              round.id,
              problem_ids
            )

          a_subs = Map.get(subs_data, duel.player_a.user_id, %{})
          b_subs = Map.get(subs_data, duel.player_b.user_id, %{})

          problems_info =
            problems
            |> Enum.zip(problem_points)
            |> Enum.map(fn {p, pts} ->
              a_data = Map.get(a_subs, p.id, %{status: "none", time: nil})
              b_data = Map.get(b_subs, p.id, %{status: "none", time: nil})

              winner =
                cond do
                  a_data.status == "solved" && b_data.status != "solved" ->
                    :player_a

                  b_data.status == "solved" && a_data.status != "solved" ->
                    :player_b

                  a_data.status == "solved" && b_data.status == "solved" ->
                    if DateTime.compare(a_data.time, b_data.time) == :lt,
                      do: :player_a,
                      else: :player_b

                  true ->
                    :none
                end

              %{
                letter: p.letter,
                points: pts,
                winner: winner
              }
            end)

          a_score =
            problems_info
            |> Enum.filter(&(&1.winner == :player_a))
            |> Enum.map(& &1.points)
            |> Enum.sum()

          b_score =
            problems_info
            |> Enum.filter(&(&1.winner == :player_b))
            |> Enum.map(& &1.points)
            |> Enum.sum()

          {a_name, b_name, is_player_a, a_score, b_score, problems_info}
        end
      end || {nil, nil, false, 0, 0, []}

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       round: round,
       problem: problem,
       problems: problems,
       problem_letter: String.upcase(problem_letter),
       statement_html: statement_html,
       locked: locked,
       round_unlock_time: round_unlock_time,
       round_end_time: round_end_time,
       now: now,
       time_remaining: time_remaining,
       unlock_ts: unlock_ts,
       end_ts: end_ts,
       submissions: submissions,
       duel_a_name: duel_a_name,
       duel_b_name: duel_b_name,
       duel_is_user_a: duel_is_user_a,
       duel_a_score: duel_a_score,
       duel_b_score: duel_b_score,
       duel_problems: duel_problems
     })}
  end

  defp letter_to_index(letter) do
    case letter |> String.upcase() |> String.to_charlist() |> hd() do
      c when c >= ?A and c <= ?Z -> c - ?A
      _ -> -1
    end
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

  defp calculate_time_remaining(now, round_end_time, round_unlock_time) do
    cond do
      round_unlock_time == nil ->
        ""

      DateTime.compare(now, round_unlock_time) == :lt ->
        diff = DateTime.diff(round_unlock_time, now)
        "До начала #{format_time(diff)}"

      round_end_time && DateTime.compare(now, round_end_time) == :lt ->
        diff = DateTime.diff(round_end_time, now)
        format_time(diff)

      round_end_time && DateTime.compare(now, round_end_time) == :gt ->
        "Завершён"

      true ->
        "0 сек"
    end
  end

  defp duel_problem_class(:player_a), do: "font-bold text-blue-500"
  defp duel_problem_class(:player_b), do: "font-bold text-red-500"
  defp duel_problem_class(_), do: ""
end
