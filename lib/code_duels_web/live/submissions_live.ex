defmodule CodeDuelsWeb.SubmissionsLive do
  use CodeDuelsWeb, :live_view

  on_mount {CodeDuelsWeb.LiveAuth, :default}

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <.round_header tournament={@tournament} round_number={@round_number} active_tab="submissions" />

        <div class="mb-8 flex justify-center">
          <div>
            <h2 class="text-xl font-semibold mb-4 text-center">Счёт дуэли</h2>
            <div class="border border-base-300 rounded-b-lg rounded-tr-lg p-4">
              <div class="overflow-visible">
                <table class="table table-zebra w-auto">
                  <thead>
                    <tr>
                      <th class="text-center w-40">Участник</th>
                      <th class="text-center w-20">Счёт</th>
                      <th class="text-center w-20">Штраф</th>
                      <%= for {problem, idx} <- Enum.with_index(@problems) do %>
                        <th class="text-center w-24">
                          <div class="text-lg font-bold">{<<?A + idx>>}</div>
                          <div class="text-xs font-normal opacity-70">+{problem.points}</div>
                        </th>
                      <% end %>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for {player_name, player_data} <- @player_submissions do %>
                      <% is_current_user = @current_user && player_data.user_id == @current_user.id %>
                      <tr class="hover">
                        <td class={cell_class("font-medium whitespace-nowrap", is_current_user)}>
                          {player_name}
                        </td>
                        <td class={cell_class("text-center font-bold", is_current_user)}>
                          {player_data.score}
                        </td>
                        <td class={cell_class("text-center", is_current_user)}>
                          {player_data.penalty}
                        </td>
                        <%= for sub_data <- player_data.submissions_by_idx do %>
                          <% {prefix, time_str} = render_submission_text(sub_data) %>
                          <td class={
                            cell_class("text-center", is_current_user) ++
                              submission_class(sub_data)
                          }>
                            <div>{prefix}</div>
                            <div class="text-xs opacity-70">{time_str}</div>
                          </td>
                        <% end %>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-8 flex-wrap justify-center">
          <div class="mb-8">
            <h2 class="text-xl font-semibold mb-4 text-center">Мои посылки</h2>
            <div class="border border-base-300 rounded-lg p-4">
              <div class="overflow-visible">
                <table class="table table-zebra w-auto">
                  <thead>
                    <tr>
                      <th class="text-center w-64">Задача</th>
                      <th class="text-center w-20">Язык</th>
                      <th class="text-center w-24">Статус</th>
                      <th class="text-center w-32">Время</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= if @current_user_all_submissions == [] do %>
                      <tr class="hover">
                        <td colspan="4" class="text-center opacity-70 w-[308px]">Нет посылок</td>
                      </tr>
                    <% else %>
                      <%= for sub <- @current_user_all_submissions do %>
                        <tr class="hover">
                          <td class="text-center font-medium w-64">
                            {sub.problem_letter} — {sub.problem.title}
                          </td>
                          <td class="text-center w-20">{sub.language}</td>
                          <td class={submission_status_class(sub.status)}>{sub.status}</td>
                          <td class="text-center text-sm opacity-70 w-32">
                            {format_datetime(sub.inserted_at)}
                          </td>
                        </tr>
                      <% end %>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="mb-8">
            <h2 class="text-xl font-semibold mb-4 text-center">Посылки соперника</h2>
            <div class="border border-base-300 rounded-lg p-4">
              <div class="overflow-visible">
                <table class="table table-zebra w-auto">
                  <thead>
                    <tr>
                      <th class="text-center w-64">Задача</th>
                      <th class="text-center w-20">Язык</th>
                      <th class="text-center w-24">Статус</th>
                      <th class="text-center w-32">Время</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= if @opponent_all_submissions == [] do %>
                      <tr class="hover">
                        <td colspan="4" class="text-center opacity-70 w-[308px]">Нет посылок</td>
                      </tr>
                    <% else %>
                      <%= for sub <- @opponent_all_submissions do %>
                        <tr class="hover">
                          <td class="text-center font-medium w-64">
                            {sub.problem_letter} — {sub.problem.title}
                          </td>
                          <td class="text-center w-20">{sub.language}</td>
                          <td class={submission_status_class(sub.status)}>{sub.status}</td>
                          <td class="text-center text-sm opacity-70 w-32">
                            {format_datetime(sub.inserted_at)}
                          </td>
                        </tr>
                      <% end %>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <%= if Enum.empty?(@player_submissions) do %>
          <div class="text-center py-12 text-lg opacity-70">
            Нет данных о посылках
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"tournament_id" => tournament_id, "round_number" => round_number}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round = CodeDuels.Tournaments.get_round(tournament_id, round_number)
    round_num = String.to_integer(round_number)

    duel =
      if socket.assigns[:current_user] do
        CodeDuels.Tournaments.get_duel_for_user(
          tournament_id,
          round_num,
          socket.assigns.current_user.id
        )
      else
        nil
      end

    if is_nil(duel) do
      {:ok,
       socket
       |> put_flash(:error, "Вы не участвуете в дуэли этого раунда")
       |> push_navigate(to: "/#{tournament_id}/#{round_number}")}
    else
      problems = CodeDuels.Tournaments.get_problemset(round.problemset)
      problem_ids = Enum.map(problems, & &1.id)

      ppr = tournament.problems_per_round || 3
      start_idx = (round_num - 1) * ppr

      problem_points =
        if tournament.scores do
          Enum.slice(tournament.scores, start_idx, ppr)
        else
          List.duplicate(1, ppr)
        end

      problems_with_points =
        Enum.zip(problems, problem_points)
        |> Enum.map(fn {problem, points} ->
          %{id: problem.id, title: problem.title, points: points}
        end)

      user_ids = [duel.player_a.user_id, duel.player_b.user_id]

      submissions_data =
        CodeDuels.Tournaments.get_submissions_for_participants(user_ids, round.id, problem_ids)

      duel_scores = duel.scores || [0, 0, 0, 0, 0]
      tournament_problem_scores = tournament.scores || [1, 1, 2, 2, 3]

      player_a_submissions_by_id = Map.get(submissions_data, duel.player_a.user_id, %{})
      player_b_submissions_by_id = Map.get(submissions_data, duel.player_b.user_id, %{})

      player_a_submissions_by_idx =
        Enum.map(problem_ids, fn pid ->
          Map.get(player_a_submissions_by_id, pid)
        end)

      player_b_submissions_by_idx =
        Enum.map(problem_ids, fn pid ->
          Map.get(player_b_submissions_by_id, pid)
        end)

      {player_a_score, player_a_penalty} =
        calculate_player_score_and_penalty(
          duel_scores,
          true,
          player_a_submissions_by_id,
          tournament_problem_scores
        )

      {player_b_score, player_b_penalty} =
        calculate_player_score_and_penalty(
          duel_scores,
          false,
          player_b_submissions_by_id,
          tournament_problem_scores
        )

      player_submissions = [
        {duel.player_a.user.username || duel.player_a.user.name || "Unknown",
         %{
           user_id: duel.player_a.user_id,
           score: Float.round(player_a_score * 1.0, 1),
           penalty: player_a_penalty,
           submissions_by_idx: player_a_submissions_by_idx
         }},
        {duel.player_b.user.username || duel.player_b.user.name || "Unknown",
         %{
           user_id: duel.player_b.user_id,
           score: Float.round(player_b_score * 1.0, 1),
           penalty: player_b_penalty,
           submissions_by_idx: player_b_submissions_by_idx
         }}
      ]

      current_user_all_submissions =
        if socket.assigns[:current_user] do
          CodeDuels.Tournaments.get_all_user_submissions(
            socket.assigns.current_user.id,
            round.id
          )
        else
          []
        end

      opponent_user_id =
        if socket.assigns[:current_user] do
          if duel.player_a.user_id == socket.assigns.current_user.id do
            duel.player_b.user_id
          else
            duel.player_a.user_id
          end
        else
          nil
        end

      opponent_all_submissions =
        if opponent_user_id do
          CodeDuels.Tournaments.get_all_user_submissions(opponent_user_id, round.id)
        else
          []
        end

      {:ok,
       assign(socket, %{
         tournament_id: tournament_id,
         round_number: round_num,
         tournament: tournament,
         problems: problems_with_points,
         player_submissions: player_submissions,
         current_user_all_submissions: current_user_all_submissions,
         opponent_all_submissions: opponent_all_submissions
       })}
    end
  end

  defp calculate_player_score_and_penalty(
         duel_scores,
         is_player_a,
         submissions,
         _tournament_problem_scores
       )
       when is_list(duel_scores) do
    indices =
      if is_player_a do
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 0, do: i)
      else
        for(i <- 0..(length(duel_scores) - 1), rem(i, 2) == 1, do: i)
      end

    Enum.reduce(indices, {0, 0}, fn idx, {score_acc, penalty_acc} ->
      value = Enum.at(duel_scores, idx) || 0
      sub_data = Map.get(submissions, idx + 1)

      cond do
        value > 0 ->
          wrong_count = if sub_data && sub_data.wrong_count, do: sub_data.wrong_count, else: 0
          {score_acc + 1, penalty_acc + wrong_count}

        value < 0 ->
          wrong_count =
            if sub_data && sub_data.wrong_count, do: sub_data.wrong_count, else: abs(value)

          {score_acc, penalty_acc + wrong_count}

        true ->
          {score_acc, penalty_acc}
      end
    end)
  end

  defp cell_class(base_class, highlight?) do
    if highlight? do
      List.wrap(base_class) ++ ["bg-yellow-500/10"]
    else
      List.wrap(base_class)
    end
  end

  defp submission_class(nil), do: []

  defp submission_class(%{status: "solved"}) do
    ["text-green-600", "font-bold"]
  end

  defp submission_class(%{status: "unsolved"}) do
    ["text-red-600"]
  end

  defp submission_class(%{status: "pending"}) do
    ["text-yellow-600"]
  end

  defp submission_class(%{status: "none"}) do
    ["text-gray-400"]
  end

  defp render_submission_text(nil) do
    {"-", ""}
  end

  defp render_submission_text(%{status: "none"}) do
    {"-", ""}
  end

  defp render_submission_text(%{status: "solved", wrong_count: wc, time: time}) do
    prefix = if wc && wc > 0, do: "+#{wc}", else: "+"
    time_str = if time, do: format_time(time), else: ""
    {prefix, time_str}
  end

  defp render_submission_text(%{status: "unsolved", wrong_count: wc, time: time}) do
    prefix = if wc && wc > 0, do: "-#{wc}", else: "-"
    time_str = if time, do: format_time(time), else: ""
    {prefix, time_str}
  end

  defp render_submission_text(%{status: "pending", wrong_count: wc, time: time}) do
    prefix = if wc && wc > 0, do: "?#{wc}", else: "?"
    time_str = if time, do: format_time(time), else: ""
    {prefix, time_str}
  end

  defp format_time(%DateTime{} = dt) do
    time = DateTime.to_naive(dt)

    NaiveDateTime.to_time(time)
    |> Time.to_string()
    |> String.slice(0, 5)
    |> then(&"@#{&1}")
  end

  defp format_time(_), do: ""

  defp submission_status_class(status) do
    case status do
      "accepted" -> "text-center font-bold text-green-600"
      "solved" -> "text-center font-bold text-green-600"
      "rejected" -> "text-center font-bold text-red-600"
      "wrong" -> "text-center font-bold text-red-600"
      "pending" -> "text-center font-bold text-yellow-600"
      _ -> "text-center"
    end
  end

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)
  end

  defp format_datetime(_), do: "-"
end
