defmodule CodeDuels.Repo.Migrations.CreateParticipant do
  use Ecto.Migration

  def change do
    create table(:participant) do
      add :user, references(:users), null: false
      add :tournament, references(:tournament), null: false
    end
  end
end
