defmodule CodeDuelsWeb.SubmissionViewLive do
  use CodeDuelsWeb, :live_view

  import CodeDuelsWeb.Helpers.SubmissionHelpers

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <.link
          navigate={"/tournament/#{@tournament_id}/#{@round_number}/submissions"}
          class="link link-hover text-sm opacity-70 mb-4 inline-block"
        >
          &larr; Назад к посылкам
        </.link>

        <.round_header tournament={@tournament} round_number={@round_number} active_tab="submissions" />

        <%= if @error == :forbidden do %>
          <div class="card bg-base-200 shadow-xl mt-4">
            <div class="card-body text-center py-12">
              <p class="text-lg opacity-70">У вас нет доступа к этой посылке</p>
            </div>
          </div>
        <% else %>
          <div class="grid gap-6 lg:grid-cols-3">
            <div class="lg:col-span-2">
              <div class="card bg-base-200 shadow-xl">
                <div class="card-body">
                  <h2 class="card-title">Решение</h2>
                  <pre class="overflow-x-auto rounded-lg p-4 text-sm font-mono max-h-[600px] overflow-y-auto"><code id="submission-code"
                    phx-hook="CodeBlock"
                    tabindex="0"
                    class={"language-#{highlight_class(@submission.language)}"}
                    phx-no-curly-interpolation><%= @submission.code %></code></pre>
                </div>
              </div>

              <%= if @submission.status in [:pending, :testing] do %>
                <div class="card bg-base-200 shadow-xl mt-6">
                  <div class="card-body text-center py-8">
                    <p class="text-lg text-yellow-600 font-semibold">Тестируется...</p>
                  </div>
                </div>
              <% end %>

              <%= if @submission.status == :done do %>
                <div class="card bg-base-200 shadow-xl mt-6">
                  <div class="card-body">
                    <h2 class="card-title">Результаты тестов</h2>
                    <p class="text-sm mb-2">Пройдено {@submission.tests_passed}</p>
                    <%= if @submission.test_results != [] do %>
                      <div class="overflow-x-auto">
                        <table class="table table-zebra w-full">
                          <thead>
                            <tr>
                              <th>Тест</th>
                              <th>Вердикт</th>
                              <th>Время</th>
                              <th>Код выхода</th>
                            </tr>
                          </thead>
                          <tbody>
                            <%= for tr <- @submission.test_results do %>
                              <tr>
                                <td class="font-mono">{tr.test}</td>
                                <td class={verdict_class(tr.verdict)}>{verdict_text(tr.verdict)}</td>
                                <td>{tr.time_ms} мс</td>
                                <td class="font-mono">{tr.exit_code}</td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>

            <div>
              <div class="card bg-base-200 shadow-xl">
                <div class="card-body">
                  <h2 class="card-title">Информация</h2>
                  <table class="table table-zebra w-full text-xs">
                    <tbody>
                      <tr>
                        <td class="font-semibold">Задача</td>
                        <td>
                          <.link
                            navigate={"/tournament/#{@tournament_id}/#{@round_number}/problem?letter=#{@submission.problem_letter}"}
                            class="link link-hover text-primary"
                          >
                            {@submission.problem_letter}. {@submission.problem.title}
                          </.link>
                        </td>
                      </tr>
                      <tr>
                        <td class="font-semibold">Язык</td>
                        <td>
                          <div class="flex items-center gap-1.5">
                            <img
                              :if={language_logo_url(@submission.language)}
                              src={language_logo_url(@submission.language)}
                              class="w-4 h-4"
                              alt=""
                            />
                            {language_display(@submission.language)}
                          </div>
                        </td>
                      </tr>
                      <tr>
                        <td class="font-semibold">Отправлено</td>
                        <td>{format_datetime(@submission.inserted_at)}</td>
                      </tr>
                      <tr>
                        <td class="font-semibold">Статус</td>
                        <td class={submission_status_class(@submission)}>
                          {submission_status_text(@submission)}
                        </td>
                      </tr>

                      <%= if @submission.message && @submission.message != "" do %>
                        <tr>
                          <td class="font-semibold">Сообщение</td>
                          <td>
                            <pre class="whitespace-pre-wrap font-mono text-xs"><%= @submission.message %></pre>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(
        %{
          "tournament_id" => tournament_id,
          "round_number" => round_number,
          "submission_id" => submission_id
        },
        _session,
        socket
      ) do
    tournament = CodeDuels.Tournaments.get_tournament!(tournament_id)
    round_num = String.to_integer(round_number)
    submission = CodeDuels.Tournaments.get_submission!(submission_id)

    current_user = socket.assigns[:current_user]

    if submission.user_id == current_user.id do
      CodeDuelsWeb.Endpoint.subscribe("submission:#{submission.id}")

      {:ok,
       assign(socket, %{
         tournament_id: tournament_id,
         round_number: round_num,
         tournament: tournament,
         submission: submission,
         error: nil
       })}
    else
      {:ok,
       assign(socket, %{
         tournament_id: tournament_id,
         round_number: round_num,
         tournament: tournament,
         submission: nil,
         error: :forbidden
       })}
    end
  end

  def handle_info(%{event: event, payload: _payload}, socket)
      when event in ["pending", "testing"] do
    submission = %{socket.assigns.submission | status: String.to_existing_atom(event)}
    {:noreply, assign(socket, :submission, submission)}
  end

  def handle_info(%{event: "done", payload: result}, socket) do
    passed = Enum.count(result.test_cases || [], &(&1.verdict == :accepted))

    test_results =
      Enum.map(result.test_cases || [], fn tc ->
        %CodeDuels.Tournaments.TestResult{
          test: tc.test,
          verdict: tc.verdict,
          time_ms: tc.time_ms,
          exit_code: tc.exit_code
        }
      end)

    submission = %{
      socket.assigns.submission
      | status: :done,
        verdict: result.verdict,
        message: result.message,
        tests_passed: passed,
        test_results: test_results
    }

    {:noreply, assign(socket, :submission, submission)}
  end

  def handle_info(%{event: "failed", payload: message}, socket) do
    submission = %{
      socket.assigns.submission
      | status: :failed,
        message: message
    }

    {:noreply, assign(socket, :submission, submission)}
  end

  def handle_info(%{event: _event, payload: _result}, socket), do: {:noreply, socket}

  defp verdict_class(:accepted), do: "font-bold text-green-600"
  defp verdict_class(:wrong_answer), do: "font-bold text-red-600"
  defp verdict_class(:time_limit), do: "font-bold text-orange-500"
  defp verdict_class(:memory_limit), do: "font-bold text-orange-500"
  defp verdict_class(:runtime_error), do: "font-bold text-red-600"
  defp verdict_class(:compile_error), do: "font-bold text-purple-600"
  defp verdict_class(:runner_error), do: "font-bold text-red-800"
  defp verdict_class(:unknown_lang), do: "font-bold text-gray-500"
  defp verdict_class(_), do: ""

  defp verdict_text(:accepted), do: "Принято"
  defp verdict_text(:wrong_answer), do: "Неверный ответ"
  defp verdict_text(:time_limit), do: "Превышено время"
  defp verdict_text(:memory_limit), do: "Превышена память"
  defp verdict_text(:runtime_error), do: "Ошибка выполнения"
  defp verdict_text(:compile_error), do: "Ошибка компиляции"
  defp verdict_text(:runner_error), do: "Ошибка проверки"
  defp verdict_text(:unknown_lang), do: "Неизвестный язык"
  defp verdict_text(_), do: ""
end
