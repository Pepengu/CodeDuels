defmodule CodeDuels.Repo.Migrations.CreateSubmission do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE submission_status AS ENUM ('pending', 'testing', 'done', 'failed')"

    execute "CREATE TYPE submission_verdict AS ENUM ('accepted', 'wrong_answer', 'time_limit', 'memory_limit', 'runtime_error', 'compile_error', 'runner_error', 'unknown_lang')"

    create table(:submissions) do
      add :user_id, references(:users)
      add :round_id, references(:round)
      add :problem_id, references(:problems)

      add :language, :string, null: false
      add :code, :text, null: false
      add :status, :submission_status, default: "pending", null: false
      add :problem_letter, :string, null: false
      add :verdict, :submission_verdict
      add :message, :text

      timestamps(type: :utc_datetime)
    end
  end
end
