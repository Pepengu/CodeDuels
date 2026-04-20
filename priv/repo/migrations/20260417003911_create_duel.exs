defmodule CodeDuels.Repo.Migrations.CreateDuel do
  use Ecto.Migration

  def change do
    create table(:duel) do
      add :player_a_id, references(:participant), null: false
      add :player_b_id, references(:participant), null: false
      add :tournament_id, references(:tournament), null: false
      add :round_number, :integer, null: false

      add :scores, {:array, :integer},
        default: [0, 0, 0, 0, 0],
        comment:
          "-score for playerA, score for playerB, 0 for none. The score value shows the penality"

      add :status, :string, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:duel, [:tournament_id, :round_number])
    create index(:duel, [:player_a_id])
    create index(:duel, [:player_b_id])
  end
end
