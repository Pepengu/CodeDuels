defmodule CodeDuels.Runner.Docker do
  @behaviour CodeDuels.Runner

  @impl true
  def languages() do
    [
      gnu_cpp17: "GNU C++ 17",
      gnu_cpp23: "GNU C++ 23",
      visual_cpp: "Visual C++",
      python: "Python3",
      pypy: "PyPy3",
      java: "Java",
      go: "Go"
    ]
  end

  @impl true
  def language_info do
    %{
      "cpp" => %{
        display: "C++",
        color: "#00599C",
        logo: "cplusplus",
        highlight: "cpp"
      },
      "gnu_cpp17" => %{
        display: "GNU C++ 17",
        color: "#00599C",
        logo: "cplusplus",
        highlight: "cpp"
      },
      "gnu_cpp23" => %{
        display: "GNU C++ 23",
        color: "#00599C",
        logo: "cplusplus",
        highlight: "cpp"
      },
      "visual_cpp" => %{
        display: "Visual C++",
        color: "#00599C",
        logo: "cplusplus",
        highlight: "cpp"
      },
      "python" => %{display: "Python3", color: "#3776AB", logo: "python", highlight: "python"},
      "pypy" => %{display: "PyPy3", color: "#3776AB", logo: "python", highlight: "python"},
      "java" => %{display: "Java", color: "#ED8B00", logo: "java", highlight: "java"},
      "go" => %{display: "Go", color: "#00ADD8", logo: "go", highlight: "go"}
    }
  end

  @impl true
  def language_family(language) do
    case language do
      "gnu_cpp17" -> "cpp"
      "gnu_cpp23" -> "cpp"
      "visual_cpp" -> "cpp"
      "pypy" -> "python"
      l -> l
    end
  end

  @spec to_verdict(String.t()) :: atom()
  defp to_verdict(verdict) do
    case verdict do
      "accepted" -> :accepted
      "wrong_answer" -> :wrong_answer
      "time_limit" -> :time_limit
      "memory_limit" -> :memory_limit
      "runtime_error" -> :runtime_error
      "compile_error" -> :compile_error
      "runner_error" -> :runner_error
      "unknown_lang" -> :unknown_lang
    end
  end

  defp decode_test_case(tc) do
    %{
      test: tc["test"],
      verdict: to_verdict(tc["verdict"]),
      time_ms: tc["time_ms"],
      exit_code: tc["exit_code"]
    }
  end

  defp decode_runner_result(result) do
    %{
      verdict: to_verdict(result["verdict"]),
      message: result["message"],
      test_cases: Enum.map(result["test_cases"] || [], &decode_test_case/1)
    }
  end

  @impl true
  def language_highlight_class(language) do
    case Map.get(language_info(), language) do
      %{highlight: hl} -> hl
      _ -> ""
    end
  end

  @impl true
  def submit_code(source_code, language, problem_id, _opts \\ []) do
    try do
      problem = CodeDuels.Problems.get_problem!(problem_id)

      config =
        %{language: language, time_limit_ms: problem.time_limit_ms, source: source_code}
        |> Jason.encode!()

      {json, _exit_code} =
        System.cmd("docker", [
          "run",
          "--rm",
          "--network=none",
          "--memory=#{problem.memory_limit_kb}k",
          "--cpus=1",
          "--pids-limit=100",
          "--cap-drop=ALL",
          "--security-opt=no-new-privileges",
          "--tmpfs",
          "/tmp:rw,exec,nosuid,size=64m",
          "-v",
          "#{problem.files_path}/tests:/code/tests:ro",
          "-v",
          "#{problem.checker}:/code/checker.cpp:ro",
          "code-duels-runner",
          config
        ])

      {:ok, Jason.decode!(json) |> decode_runner_result()}
    rescue
      e -> {:error, "Docker failed: #{Exception.message(e)}"}
    end
  end
end
