defmodule CodeDuels.Tournaments.TestResult do
  use Ecto.Schema

  schema "test_results" do
    field :test, :string
    field :verdict, CodeDuels.Tournaments.Verdict
    field :time_ms, :integer
    field :exit_code, :integer

    belongs_to :submission, CodeDuels.Tournaments.Submission
  end
end
