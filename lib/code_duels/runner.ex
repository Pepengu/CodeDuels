defmodule CodeDuels.Runner do
  @type verdict :: :accepted | :wrong_answer | :time_limit | :memory_limit | :runtime_error | :compile_error |
                   :runner_error | :unknown_lang

  @type test_case :: %{
    test: String.t(),
    verdict: verdict(),
    time_ms: integer(),
    exit_code: integer()
  }

  @type submission :: %{
    verdict: verdict(),
    message: String.t() | nil,
    test_cases: [test_case()]
  }


  @callback languages() :: [String.t()]
  @callback submit_code(source_code :: String.t(), language :: String.t(), problem_id :: integer(), opts :: keyword()) :: submission()
end
