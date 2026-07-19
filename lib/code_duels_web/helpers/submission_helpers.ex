defmodule CodeDuelsWeb.Helpers.SubmissionHelpers do
  @adapter Application.compile_env(:code_duels, :runner)[:adapter]

  @language_info @adapter.language_info()

  def language_display(internal) do
    case Map.get(@language_info, internal) do
      %{display: display} -> display
      _ -> internal
    end
  end

  def language_color(internal) do
    case Map.get(@language_info, internal) do
      %{color: color} -> color
      _ -> "#6B7280"
    end
  end

  def language_logo(internal) do
    case Map.get(@language_info, internal) do
      %{logo: logo} -> logo
      _ -> nil
    end
  end

  def language_logo_url(internal) do
    case language_logo(internal) do
      nil -> nil
      key -> "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{key}/#{key}-original.svg"
    end
  end

  def language_family(internal) do
    @adapter.language_family(internal)
  end

  def submission_status_class(sub) do
    cond do
      sub.status == :done && sub.verdict == :accepted ->
        "font-bold text-green-600"

      sub.status == :done && sub.verdict in [:wrong_answer, :runtime_error] ->
        "font-bold text-red-600"

      sub.status == :done && sub.verdict in [:time_limit, :memory_limit] ->
        "font-bold text-orange-500"

      sub.status == :done && sub.verdict == :compile_error ->
        "font-bold text-purple-600"

      sub.status == :done && sub.verdict == :runner_error ->
        "font-bold text-red-800"

      sub.status == :done && sub.verdict == :unknown_lang ->
        "font-bold text-gray-500"

      sub.status == :testing ->
        "font-bold text-yellow-600"

      sub.status == :pending ->
        "font-bold text-yellow-600"

      sub.status == :failed ->
        "font-bold text-red-600"

      true ->
        ""
    end
  end

  def submission_status_text(sub) do
    cond do
      sub.status == :pending -> "Ожидание"
      sub.status == :testing -> "Тестирование"
      sub.status == :done && sub.verdict == :accepted -> "Принято"
      sub.status == :done && sub.verdict == :wrong_answer -> "Неверный ответ"
      sub.status == :done && sub.verdict == :time_limit -> "Превышено время"
      sub.status == :done && sub.verdict == :memory_limit -> "Превышена память"
      sub.status == :done && sub.verdict == :runtime_error -> "Ошибка выполнения"
      sub.status == :done && sub.verdict == :compile_error -> "Ошибка компиляции"
      sub.status == :done && sub.verdict == :runner_error -> "Ошибка проверки"
      sub.status == :done && sub.verdict == :unknown_lang -> "Неизвестный язык"
      sub.status == :failed -> "Ошибка"
      true -> to_string(sub.status)
    end
  end

  def highlight_class(language) do
    @adapter.language_highlight_class(language)
  end

  def format_datetime(nil), do: "Не задано"

  def format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)
  end

  def format_datetime(_), do: "-"
end
