defmodule CodeDuels.Repo.Migrations.CreateTournament do
  use Ecto.Migration

  def change do
    create table(:tournament) do
      add :rounds, :int, null: false, default: 5
      add :round_time, :integer, null: false, default: 2400
      add :intermission_time, :integer, null: false, default: 60
      add :penality, :int, null: false, default: 5
      add :problems_per_round, :int, null: false, default: 5
      add :scores, {:array, :integer}, null: false, default: [1, 1, 2, 2, 3]
      add :max_participants, :int, null: false, default: 32
      add :name, :string, null: false
      add :is_open, :bool, null: false, default: true
      add :start_time, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tournament, [:name])
  end
end
