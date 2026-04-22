defmodule CodeDuels.Repo.Migrations.CreateRound do
  use Ecto.Migration

  def change do
    create table(:round) do
      add :tournament_id, references(:tournament), null: false
      add :round_number, :integer, null: false
      add :problemset, {:array, :integer}, null: false
      add :start_time, :time, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
