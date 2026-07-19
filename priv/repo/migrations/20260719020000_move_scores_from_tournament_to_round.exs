defmodule CodeDuels.Repo.Migrations.MoveScoresFromTournamentToRound do
  use Ecto.Migration

  def change do
    alter table(:round) do
      add :scores, {:array, :integer}
    end

    alter table(:tournament) do
      remove :scores
    end
  end
end
