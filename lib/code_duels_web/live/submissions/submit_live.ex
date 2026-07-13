defmodule CodeDuelsWeb.SubmitLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.Helpers.SubmissionHelpers
  import CodeDuelsWeb.SubmissionsTable
  import CodeDuelsWeb.Helpers.TimeHelpers

  alias CodeDuels.Tournaments.Submission

  @adapter Application.compile_env(:code_duels, :runner)[:adapter]

  @languages @adapter.languages()
             |> Enum.map(fn {internal, display} -> {display, to_string(internal)} end)

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
                    phx-hook="LanguageSelectHook"
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

              <div class="card bg-base-200 shadow-xl">
                <div class="card-body">
                  <h2 class="card-title">Код решения</h2>
                  <div
                    id="code-editor"
                    phx-hook="CodeInput"
                    class="relative border border-base-300 rounded-lg"
                    style="min-height:500px"
                  >
                    <textarea
                      id="submission_code"
                      name="submission[code]"
                      class="absolute inset-0 w-full h-full bg-transparent text-transparent caret-primary font-mono text-sm leading-normal p-4 resize-none outline-none z-10"
                      phx-no-curly-interpolation
                      placeholder="Введите ваш код здесь..."
                      spellcheck="false"
                    ><%= @form.params["code"] %></textarea>
                    <pre class="absolute inset-0 rounded-lg p-4 font-mono text-sm leading-normal pointer-events-none whitespace-pre-wrap bg-base-300"><code class={"language-#{@highlight_class}"}><%= @form.params["code"] %></code></pre>
                  </div>
                </div>
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
            <.submissions_table
              title="Последние попытки"
              submissions={@submissions}
              tournament_id={@tournament_id}
              round_number={@round_number}
              show_problem?
            />
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

  def mount(
        %{"tournament_id" => tournament_id, "round_number" => round_number} = params,
        _session,
        socket
      ) do
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round = CodeDuels.Tournaments.get_round(tournament_id, round_number)
    round_num = String.to_integer(round_number)

    problems = CodeDuels.Tournaments.Problemset.list_problems(round.problemset)

    duel =
      CodeDuels.Tournaments.get_duel_for_user(
        tournament_id,
        round_num,
        socket.assigns[:current_user].id
      )

    participant_id =
      if duel do
        current_user_id = socket.assigns[:current_user].id

        if duel.player_a.user_id == current_user_id do
          CodeDuelsWeb.Endpoint.subscribe("opponent:#{duel.player_b_id}")
          duel.player_a_id
        else
          CodeDuelsWeb.Endpoint.subscribe("opponent:#{duel.player_a_id}")
          duel.player_b_id
        end
      end

    problem_options =
      [
        {"- Выберите задачу -", ""}
        | Enum.map(problems, fn p -> {"#{p.letter} - #{p.title}", to_string(p.id)} end)
      ]

    preselected_problem_id =
      if letter = params["letter"] do
        case Enum.find(problems, &(&1.letter == String.upcase(letter))) do
          nil -> nil
          p -> to_string(p.id)
        end
      end

    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin
    round_state = CodeDuels.Tournaments.RoundState.compute(tournament, round_num, is_admin)

    round_time_minutes = div(tournament.round_time, 60)

    initial = if preselected_problem_id, do: %{"problem_id" => preselected_problem_id}, else: %{}

    form =
      initial
      |> Submission.create_changeset()
      |> to_form(as: :submission)

    schedule_timer()

    submissions =
      CodeDuels.Tournaments.get_last_n_user_submissions(
        socket.assigns.current_user.id,
        round.id,
        3
      )

    language = form.params["language"]
    highlight_class = if language && language != "", do: highlight_class(language), else: ""

    {:ok,
     assign(socket, %{
       tournament_id: tournament_id,
       tournament: tournament,
       round_number: round_num,
       round_id: round.id,
       problems: problems,
       problem_options: problem_options,
       locked: round_state.locked,
       time_based_locked: round_state.time_based_locked,
       round_unlock_time: round_state.round_unlock_time,
       round_end_time: round_state.round_end_time,
       now: round_state.now,
       round_time_minutes: round_time_minutes,
       time_remaining: round_state.time_remaining,
       languages: @languages,
       form: form,
       error: :none,
       participant_id: participant_id,
       submissions: submissions,
       highlight_class: highlight_class
     })}
  end

  def handle_event("validate", %{"submission" => params}, socket) do
    form = %{socket.assigns.form | params: params}
    language = params["language"]
    highlight_class = if language && language != "", do: highlight_class(language), else: ""
    {:noreply, assign(socket, form: form, highlight_class: highlight_class)}
  end

  def handle_event("restore_language", %{"language" => lang}, socket) do
    form = %{socket.assigns.form | params: Map.put(socket.assigns.form.params, "language", lang)}
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
    %{tournament_id: _tournament_id, round_id: round_id, problems: problems} = socket.assigns

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

    case CodeDuels.Tournaments.SubmissionJudge.judge(attrs) do
      {:ok, sub} ->
        CodeDuelsWeb.Endpoint.subscribe("submission:#{sub.id}")
        submissions = [sub | socket.assigns.submissions] |> Enum.take(3)
        {:noreply, assign(socket, error: :success, submissions: submissions)}

      {:error, changeset} ->
        form = to_form(changeset, as: :submission)
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_info(%{event: "done", payload: result}, socket) do
    CodeDuelsWeb.Endpoint.broadcast!("opponent:#{socket.assigns.participant_id}", "done", result)

    [latest | rest] = socket.assigns.submissions
    passed = Enum.count(result[:test_cases] || [], &(&1[:verdict] == :accepted))

    updated = %{
      latest
      | status: :done,
        verdict: result[:verdict],
        message: result[:message],
        tests_passed: passed
    }

    {:noreply, assign(socket, submissions: [updated | rest])}
  end

  def handle_info(%{event: "failed", payload: message}, socket) do
    CodeDuelsWeb.Endpoint.broadcast!("opponent:#{socket.assigns.participant_id}", "done", %{
      "verdict" => "failed",
      "message" => message
    })

    [latest | rest] = socket.assigns.submissions
    updated = %{latest | status: :failed, message: message}

    {:noreply, assign(socket, submissions: [updated | rest])}
  end

  def handle_info(%{event: _event, payload: _result}, socket), do: {:noreply, socket}

  def handle_info(:tick, socket) do
    schedule_timer()
    is_admin = socket.assigns[:current_user] && socket.assigns[:current_user].is_admin

    round_state =
      CodeDuels.Tournaments.RoundState.compute(
        socket.assigns.tournament,
        socket.assigns.round_number,
        is_admin
      )

    {:noreply,
     assign(socket,
       now: round_state.now,
       locked: round_state.locked,
       time_based_locked: round_state.time_based_locked,
       time_remaining: round_state.time_remaining
     )}
  end
end
