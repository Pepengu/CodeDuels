defmodule CodeDuels.Tournaments.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participant" do
    field :score, :float
    field :status, :string

    belongs_to :user, CodeDuels.Accounts.User
    belongs_to :tournament, CodeDuels.Tournaments.Tournament

    timestamps(type: :utc_datetime)
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:score, :status, :user_id, :tournament_id])
    |> validate_required([:user_id, :tournament_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tournament_id)
    |> unique_constraint([:user_id, :tournament_id])
  end
end
