defmodule CodeDuelsWeb.SubmissionsTable do
  use Phoenix.Component
  use Gettext, backend: CodeDuelsWeb.Gettext
  import CodeDuelsWeb.Helpers.SubmissionHelpers

  attr :title, :string, required: true
  attr :submissions, :list, required: true
  attr :tournament_id, :string, required: true
  attr :round_number, :integer, required: true
  attr :show_problem?, :boolean, default: true

  def submissions_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body p-4">
        <h3 class="font-semibold text-center mb-2">{@title}</h3>
        <table class="table table-zebra w-full text-xs">
          <thead>
            <tr>
              <th :if={@show_problem?}>Задача</th>
              <th>Язык</th>
              <th>Время</th>
              <th>Статус</th>
              <th>Тесты</th>
            </tr>
          </thead>
          <tbody>
            <%= if @submissions == [] do %>
              <tr>
                <td colspan={if @show_problem?, do: 5, else: 4} class="text-center opacity-70">
                  Нет попыток
                </td>
              </tr>
            <% else %>
              <%= for sub <- @submissions do %>
                <tr>
                  <td :if={@show_problem?} class="font-semibold text-center">
                    <.link
                      navigate={"/tournament/#{@tournament_id}/#{@round_number}/problem?letter=#{sub.problem_letter}"}
                      class="link link-hover text-primary"
                    >
                      {sub.problem_letter}
                    </.link>
                  </td>
                  <td>
                    <div class="flex items-center gap-2 whitespace-nowrap">
                      <img
                        :if={language_logo_url(sub.language)}
                        src={language_logo_url(sub.language)}
                        class="w-4 h-4 shrink-0"
                        alt=""
                      />
                      {language_display(sub.language)}
                    </div>
                  </td>
                  <td class="opacity-70">{format_datetime(sub.inserted_at)}</td>
                  <td class={submission_status_class(sub)}>
                    <.link
                      navigate={"/tournament/#{@tournament_id}/#{@round_number}/submissions/#{sub.id}"}
                      class="hover:underline"
                    >
                      {submission_status_text(sub)}
                    </.link>
                  </td>
                  <td class="text-center">
                    <%= if sub.status == :done do %>
                      {sub.tests_passed}
                    <% else %>
                      &mdash;
                    <% end %>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
