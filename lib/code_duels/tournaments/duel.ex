defmodule CodeDuels.Tournaments.Duel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "duel" do
    field :scores, {:array, :integer}
    field :status, :string
    field :round_number, :integer

    belongs_to :player_a, CodeDuels.Tournaments.Participant
    belongs_to :player_b, CodeDuels.Tournaments.Participant
    belongs_to :tournament, CodeDuels.Tournaments.Tournament

    timestamps(type: :utc_datetime)
  end

  def changeset(duel, attrs) do
    duel
    |> cast(attrs, [
      :scores,
      :status,
      :round_number,
      :player_a_id,
      :player_b_id,
      :tournament_id
    ])
    |> validate_required([:player_a_id, :player_b_id, :tournament_id, :round_number])
    |> foreign_key_constraint(:player_a_id)
    |> foreign_key_constraint(:player_b_id)
    |> foreign_key_constraint(:tournament_id)
    |> check_constraint(:player_a_not_player_b, name: :player_a_and_player_b_differ)
  end
end
