defmodule CodeDuels.Tournaments.SubmissionJudge do
  alias CodeDuels.Tournaments.Submission
  alias CodeDuels.Tournaments.TestResult

  @type attrs :: %{
          required(:code) => String.t(),
          required(:language) => String.t(),
          required(:problem_id) => integer(),
          required(:user_id) => integer(),
          required(:round_id) => integer(),
          required(:problem_letter) => String.t()
        }

  @adapter Application.compile_env(:code_duels, :runner)[:adapter]

  @spec judge(attrs()) :: {:ok, %Submission{}} | {:error, Ecto.Changeset.t()}
  def judge(attrs) do
    with {:ok, submission} <- Submission.create_changeset(attrs) |> CodeDuels.Repo.insert() do
      Phoenix.PubSub.broadcast(CodeDuels.PubSub, "submission:#{submission.id}", %{
        event: "pending",
        payload: %{}
      })

      Task.Supervisor.start_child(CodeDuels.SubmissionTaskSupervisor, fn ->
        submission =
          Submission.changeset(submission, %{status: :testing}) |> CodeDuels.Repo.update!()

        Phoenix.PubSub.broadcast(CodeDuels.PubSub, "submission:#{submission.id}", %{
          event: "testing",
          payload: %{}
        })

        case @adapter.submit_code(attrs.code, attrs.language, attrs.problem_id) do
          {:ok, result} ->
            tests_passed = Enum.count(result.test_cases, &(&1.verdict == :accepted))

            submission =
              Submission.changeset(submission, %{
                status: :done,
                verdict: result.verdict,
                message: result.message,
                tests_passed: tests_passed
              })
              |> CodeDuels.Repo.update!()

            Enum.each(result.test_cases, fn tc ->
              CodeDuels.Repo.insert!(%TestResult{
                submission_id: submission.id,
                test: tc.test,
                verdict: tc.verdict,
                time_ms: tc.time_ms,
                exit_code: tc.exit_code
              })
            end)

            Phoenix.PubSub.broadcast(CodeDuels.PubSub, "submission:#{submission.id}", %{
              event: "done",
              payload: result
            })

          {:error, message} ->
            submission =
              Submission.changeset(submission, %{
                status: :failed,
                message: message
              })
              |> CodeDuels.Repo.update!()

            Phoenix.PubSub.broadcast(CodeDuels.PubSub, "submission:#{submission.id}", %{
              event: "failed",
              payload: message
            })
        end
      end)

      {:ok, submission}
    end
  end
end
