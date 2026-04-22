defmodule CodeDuels.Tournaments.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submissions" do
    field :language, :string
    field :code, :string
    field :status, :string, default: "pending"

    belongs_to :user, CodeDuels.Accounts.User
    belongs_to :round, CodeDuels.Tournaments.Round
    belongs_to :problem, CodeDuels.Problems.Problem

    timestamps(type: :utc_datetime)
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:user_id, :round_id, :problem_id, :language, :code, :status])
    |> validate_required([:user_id, :round_id, :problem_id, :language, :code])
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> validate_length(:code, min: 1)
  end
end
