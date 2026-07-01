
defmodule CodeDuels.Runner.Docker do
  @behaviour CodeDuels.Runner
  
  @impl true
  def languages() do 
    [
      "gnu_cpp17",
      "gnu_cpp23",
      "visual_cpp",
      "python",
      "pypy",
      "java",
      "go",
    ]
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
  def submit_code(source_code, language, problem_id, _opts \\ []) do
    problem = CodeDuels.Problems.get_problem!(problem_id)

    config = %{language: language, time_limit_ms: problem.time_limit_ms, source: source_code} |>
                Jason.encode!()

    {json, _exit_code} = System.cmd("docker", [
        "run", "--rm",
        "--network=none", "--memory=#{problem.memory_limit_kb}k", "--cpus=1",
        "--pids-limit=100", "--cap-drop=ALL", "--security-opt=no-new-privileges",
        "--tmpfs", "/tmp:rw,exec,nosuid,size=64m",
        "-v", "#{problem.files_path}/tests:/code/tests:ro",
        "-v", "#{problem.checker}:/code/checker.cpp:ro",
        "code-duels-runner", config
    ])

    json |> Jason.decode!() |> decode_runner_result()
  end
end
