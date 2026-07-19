defmodule CodeDuels.Runner do
  @type verdict ::
          :accepted
          | :wrong_answer
          | :time_limit
          | :memory_limit
          | :runtime_error
          | :compile_error
          | :runner_error
          | :unknown_lang

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

  @type language_info :: %{
          display: String.t(),
          color: String.t(),
          logo: String.t() | nil,
          highlight: String.t()
        }

  @callback languages() :: keyword(String.t())
  @callback language_info() :: %{String.t() => language_info()}
  @callback language_family(language :: String.t()) :: String.t()
  @callback language_highlight_class(language :: String.t()) :: String.t()
  @callback submit_code(
              source_code :: String.t(),
              language :: String.t(),
              problem_id :: integer(),
              opts :: keyword()
            ) :: {:ok, map()} | {:error, String.t()}
end
