defmodule CodeDuels.Repo.Migrations.CreateDuel do
  use Ecto.Migration

  def change do
    create table(:duel) do
      add :playerA, references(:participant), null: false     
      add :playerB, references(:participant), null: false     
      add :scores, {:array, :integer}, null: false, default: [0, 0, 0, 0, 0], comment: "-score for playerA, score for playerB, 0 for none. The score value shows the penality"
    end
  end
end
