defmodule CodeDuels.Tournaments.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submissions" do
    field :language, :string
    field :code, :string
    field :status, CodeDuels.Tournaments.SubmissionStatus, default: :pending
    field :problem_letter, :string
    field :verdict, CodeDuels.Tournaments.Verdict
    field :message, :string
    field :tests_passed, :integer, default: 0

    belongs_to :user, CodeDuels.Accounts.User
    belongs_to :round, CodeDuels.Tournaments.Round
    belongs_to :problem, CodeDuels.Problems.Problem

    has_many :test_results, CodeDuels.Tournaments.TestResult

    timestamps(type: :utc_datetime)
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [
      :user_id,
      :round_id,
      :problem_id,
      :language,
      :code,
      :status,
      :problem_letter,
      :verdict,
      :message,
      :tests_passed
    ])
    |> validate_required([:user_id, :round_id, :problem_id, :language, :code, :problem_letter])
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> validate_length(:code, min: 1)
  end
end
