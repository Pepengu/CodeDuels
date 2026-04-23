defmodule CodeDuelsWeb.SubmitLive do
  use CodeDuelsWeb, :live_view

  alias CodeDuels.Tournaments.Submission

  @languages [
    {"C++", "cpp"},
    {"Python", "py"},
    {"Java", "java"},
    {"JavaScript", "js"},
    {"Go", "go"},
    {"Rust", "rs"}
  ]

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.live_component module={CodeDuelsWeb.RoundNotificationPopup} id="round-notification" />
      <div class="container mx-auto px-4 py-8">
        <.round_header tournament={@tournament} round_number={@round_number} active_tab="submit" />

        <div class="grid gap-6 lg:grid-cols-3">
          <div class="lg:col-span-2">
            <.form
              for={@form}
              id="submit-form"
              phx-change="validate"
              class="space-y-6"
            >
              <div class="grid grid-cols-2 gap-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text font-semibold">Язык</span>
                  </label>
                  <.input
                    field={@form[:language]}
                    type="select"
                    options={@languages}
                    class="select-bordered select w-full"
                  />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text font-semibold">Задача</span>
                  </label>
                  <.input
                    field={@form[:problem_id]}
                    type="select"
                    options={@problem_options}
                    class="select-bordered select w-full"
                  />
                </div>
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">Код решения</span>
                </label>
                <textarea
                  id="submission_code"
                  name="submission[code]"
                  class="textarea textarea-bordered font-mono text-sm h-[500px] w-full"
                  phx-no-curly-interpolation
                  placeholder="Введите ваш код здесь..."
                ><%= @form.params["code"] %></textarea>
              </div>

              <div class="submission grid grid-cols-2 gap-4 items-center">
                <div
                  class="error_box card p-2"
                  style={
                    "border-radius: 4px;
                     align-items: center;
                     justify-content: center;
                     border-radius: var(--radius-field);
                     white-space: pre-line;
                     #{error_style(@error)}"
                  }
                >
                  {error_message(@error)}
                </div>
                <button
                  type="button"
                  class="btn btn-primary btn-block"
                  phx-click="validate_submit"
                  {if @locked, do: [disabled: "disabled"], else: []}
                >
                  Отправить решение
                </button>
              </div>
            </.form>
          </div>

          <div>
            <div class="card bg-base-200 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">Информация</h2>
                <div class="overflow-x-auto">
                  <table class="table table-zebra">
                    <tbody>
                      <tr>
                        <td class="font-semibold">Время раунда</td>
                        <td>{@round_time_minutes} мин</td>
                      </tr>
                      <tr>
                        <td class="font-semibold">Осталось</td>
                        <td>{@time_remaining}</td>
                      </tr>
                      <tr>
                        <td class="font-semibold">Штраф</td>
                        <td>{@tournament.penality}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div class="card bg-base-200 shadow-xl mt-6">
              <div class="card-body">
                <h2 class="card-title">Задачи раунда</h2>
                <ul class="list-disc list-inside text-sm">
                  <%= for problem <- @problems do %>
                    <li class="mt-1">
                      <span class="font-semibold">{problem.letter}</span> — {problem.title}
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def error_message(:none), do: ""
  def error_message(:no_problem), do: "Необходимо выбрать задачу"
  def error_message(:no_code), do: "Поле кода не может быть пустым"
  def error_message(:success), do: "Задача успешно отправлена"

  def error_message(:no_problem_and_code),
    do: "Необходимо выбрать задачу \n Поле кода не может быть пустым"

  def error_message(_), do: ""

  def error_style(:none), do: "visibility: hidden"

  def error_style(:success),
    do: "background-color: var(--color-success); color: var(--color-success-content);"

  def error_style(error) when error in [:no_problem, :no_code, :no_problem_and_code] do
    "background-color: var(--color-error); color: var(--color-error-content);"
  end

  def error_style(_), do: ""

  def mount(%{"tournament_id" => tournament_id, "round_number" => round_number}, _session, socket) do
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round = CodeDuels.Tournaments.get_round(tournament_id, round_number)
    round_num = String.to_integer(round_number)

    problemset = CodeDuels.Tournaments.get_problemset(round.problemset)

    {problems, _} =
      problemset
      |> Enum.map_reduce(?A, fn problem, acc ->
        {
          %{
            id: problem.id,
            title: problem.title,
            letter: <<acc>>
          },
          acc + 1
        }
      end)

    problem_options =
      [
        {"- Выберите задачу -", ""}
        | Enum.map(problems, fn p -> {"#{p.letter} - #{p.title}", to_string(p.id)} end)
      ]

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    now = DateTime.utc_now()
    round_unlock_time = calculate_round_unlock_time(tournament, round_num)

    round_end_time =
      if round_unlock_time,
        do: DateTime.add(round_unlock_time, tournament.round_time, :second),
        else: nil

    time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt
    locked = time_based_locked && !is_admin

    round_time_minutes = div(tournament.round_time, 60)
    time_remaining = calculate_time_remaining(now, round_end_time, round_unlock_time)

    form =
      %{}
      |> Submission.create_changeset()
      |> to_form(as: :submission)

    schedule_timer()

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       round_id: round.id,
       problems: problems,
       problem_options: problem_options,
       locked: locked,
       time_based_locked: time_based_locked,
       round_unlock_time: round_unlock_time,
       round_end_time: round_end_time,
       now: now,
       round_time_minutes: round_time_minutes,
       time_remaining: time_remaining,
       languages: @languages,
       form: form,
       error: :none
     })}
  end

  def handle_event("validate", %{"submission" => params}, socket) do
    form = %{socket.assigns.form | params: params}
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("validate_submit", _params, socket) do
    form = socket.assigns.form
    params = form.params

    problem_id = params["problem_id"]
    code = params["code"]

    missing_problem = problem_id == "" or is_nil(problem_id)
    missing_code = code == "" or is_nil(code) or code |> String.trim() == ""

    cond do
      missing_problem and missing_code ->
        {:noreply, assign(socket, error: :no_problem_and_code)}

      missing_problem ->
        {:noreply, assign(socket, error: :no_problem)}

      missing_code ->
        {:noreply, assign(socket, error: :no_code)}

      true ->
        handle_event("submit", %{"submission" => params}, socket)
    end
  end

  def handle_event("submit", %{"submission" => params}, socket) do
    current_user = socket.assigns.current_user
    %{tournament_id: tournament_id, round_id: round_id, problems: problems} = socket.assigns

    problem_id = String.to_integer(params["problem_id"])
    # Find the problem letter from the loaded problems list
    problem = Enum.find(problems, &(&1.id == problem_id))
    problem_letter = if problem, do: problem.letter, else: nil

    attrs = %{
      user_id: current_user.id,
      round_id: round_id,
      problem_id: problem_id,
      problem_letter: problem_letter,
      language: params["language"],
      code: params["code"]
    }

    case CodeDuels.Tournaments.create_submission(attrs) do
      {:ok, _submission} ->
        socket =
          socket
          |> put_flash(:success, "Решение отправлено!")
          |> push_navigate(to: "/#{tournament_id}/#{socket.assigns.round_number}")

        {:noreply, assign(socket, error: :success)}

      {:error, changeset} ->
        form = to_form(changeset, as: :submission)
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_info(:tick, socket) do
    schedule_timer()
    now = DateTime.utc_now()
    round_unlock_time = socket.assigns[:round_unlock_time]
    round_end_time = socket.assigns[:round_end_time]
    is_time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    locked = is_time_based_locked && !is_admin

    time_remaining = calculate_time_remaining(now, round_end_time, round_unlock_time)

    {:noreply,
     assign(socket,
       now: now,
       locked: locked,
       time_based_locked: is_time_based_locked,
       time_remaining: time_remaining
     )}
  end

  defp calculate_round_unlock_time(tournament, round) do
    if tournament.start_time do
      offset_seconds =
        (round - 1) * tournament.round_time + (round - 1) * tournament.intermission_time

      DateTime.add(tournament.start_time, offset_seconds, :second)
    else
      nil
    end
  end

  defp schedule_timer do
    Process.send_after(self(), :tick, 1000)
  end

  defp calculate_time_remaining(now, round_end_time, round_unlock_time) do
    cond do
      round_unlock_time == nil ->
        "-"

      DateTime.compare(now, round_unlock_time) == :lt ->
        "-"

      round_end_time && DateTime.compare(now, round_end_time) == :lt ->
        diff = DateTime.diff(round_end_time, now)
        format_time(diff)

      round_end_time && DateTime.compare(now, round_end_time) == :gt ->
        "Завершён"

      true ->
        "0 сек"
    end
  end

  defp format_time(seconds) when seconds < 60, do: "#{seconds} сек"

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} мин #{remaining_seconds} сек"
  end
end
