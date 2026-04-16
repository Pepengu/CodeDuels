defmodule CodeDuels.Repo.Migrations.CreateRound do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :tournament_id, references(:users), null: false
      add :problemset, {:array, references(:problem)}, null: false
      add :start_time, :time, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
