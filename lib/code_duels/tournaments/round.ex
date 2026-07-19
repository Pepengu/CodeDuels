defmodule CodeDuels.Tournaments.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "round" do
    field :round_number, :integer
    field :problemset, {:array, :integer}
    field :start_time, :time
    field :scores, {:array, :integer}

    belongs_to :tournament, CodeDuels.Tournaments.Tournament

    timestamps(type: :utc_datetime)
  end

  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :tournament_id,
      :round_number,
      :problemset,
      :start_time,
      :scores
    ])
    |> validate_required([:tournament_id, :round_number, :problemset, :start_time])
  end
end
