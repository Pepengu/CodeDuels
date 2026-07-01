defmodule CodeDuels.Repo.Migrations.CreateSubmission do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add :user_id, references(:users)
      add :round_id, references(:round)
      add :problem_id, references(:problems)

      add :language, :string, null: false
      add :code, :text, null: false
      add :status, :string, default: "pending", null: false
      add :problem_letter, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
