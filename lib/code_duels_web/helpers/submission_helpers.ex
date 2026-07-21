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

  def verdict_label(:accepted), do: "Принято"
  def verdict_label(:wrong_answer), do: "Неверный ответ"
  def verdict_label(:time_limit), do: "Превышено время"
  def verdict_label(:memory_limit), do: "Превышена память"
  def verdict_label(:runtime_error), do: "Ошибка выполнения"
  def verdict_label(:compile_error), do: "Ошибка компиляции"
  def verdict_label(:runner_error), do: "Ошибка проверки"
  def verdict_label(:unknown_lang), do: "Неизвестный язык"

  def verdict_label(other) when is_atom(other) do
    other |> to_string() |> String.replace("_", " ")
  end

  def verdict_icon(:accepted), do: "hero-check-circle"
  def verdict_icon(:wrong_answer), do: "hero-x-circle"
  def verdict_icon(:time_limit), do: "hero-clock"
  def verdict_icon(:memory_limit), do: "hero-cpu-chip"
  def verdict_icon(:runtime_error), do: "hero-bug-ant"
  def verdict_icon(:compile_error), do: "hero-wrench-screwdriver"
  def verdict_icon(:runner_error), do: "hero-exclamation-triangle"
  def verdict_icon(:unknown_lang), do: "hero-question-mark-circle"
  def verdict_icon(_), do: "hero-information-circle"

  def verdict_style(:accepted),
    do: %{border: "border-success", text: "text-success", bar: "bg-success"}

  def verdict_style(:wrong_answer),
    do: %{border: "border-error", text: "text-error", bar: "bg-error"}

  def verdict_style(:time_limit),
    do: %{border: "border-warning", text: "text-warning", bar: "bg-warning"}

  def verdict_style(:memory_limit),
    do: %{border: "border-warning", text: "text-warning", bar: "bg-warning"}

  def verdict_style(:runtime_error),
    do: %{border: "border-error", text: "text-error", bar: "bg-error"}

  def verdict_style(:compile_error),
    do: %{border: "border-info", text: "text-info", bar: "bg-info"}

  def verdict_style(:runner_error),
    do: %{border: "border-error", text: "text-error", bar: "bg-error"}

  def verdict_style(:unknown_lang),
    do: %{border: "border-base-content", text: "text-base-content/60", bar: "bg-base-content/60"}

  def verdict_style(_),
    do: %{border: "border-base-300", text: "text-base-content", bar: "bg-base-content"}

  def donut_color(:accepted), do: "stroke-success"
  def donut_color(:wrong_answer), do: "stroke-error"
  def donut_color(:time_limit), do: "stroke-warning"
  def donut_color(:memory_limit), do: "stroke-warning"
  def donut_color(:runtime_error), do: "stroke-error"
  def donut_color(:compile_error), do: "stroke-info"
  def donut_color(:runner_error), do: "stroke-error"
  def donut_color(:unknown_lang), do: "stroke-base-content/60"
  def donut_color(_), do: "stroke-base-content"

  def format_datetime(nil), do: "Не задано"

  def format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)
  end

  def format_datetime(_), do: "-"

  def time_ago(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "только что"
      diff < 3600 -> "#{div(diff, 60)} мин. назад"
      diff < 86400 -> "#{div(diff, 3600)} ч. назад"
      diff < 604_800 -> "#{div(diff, 86400)} дн. назад"
      true -> Calendar.strftime(dt, "%d.%m.%Y")
    end
  end

  def time_ago(_), do: "-"
end
