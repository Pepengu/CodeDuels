defmodule CodeDuels.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tournament" do
    field :rounds, :integer
    field :problems_per_round, :integer
    field :round_time, :integer
    field :intermission_time, :integer
    field :penality, :integer
    field :scores, {:array, :integer}
    field :max_participants, :integer
    field :name, :string
    field :is_open, :boolean
    field :start_time, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :rounds,
      :problems_per_round,
      :round_time,
      :intermission_time,
      :penality,
      :scores,
      :max_participants,
      :name,
      :is_open,
      :start_time
    ])
    |> validate_required([:name, :is_open])
  end
end
