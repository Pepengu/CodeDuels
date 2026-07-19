defmodule CodeDuels.Repo.Migrations.CreateParticipant do
  use Ecto.Migration

  def change do
    create table(:participant) do
      add :user_id, references(:users), null: false
      add :tournament_id, references(:tournament), null: false
      add :score, :float, default: 0.0
      add :role, :string, default: "participant"

      timestamps(type: :utc_datetime)
    end

    create index(:participant, [:tournament_id])
    create index(:participant, [:user_id])
  end
end
