defmodule CodeDuels.Repo.Migrations.CreateTestResults do
  use Ecto.Migration

  def change do
    create table(:test_results) do
      add :submission_id, references(:submissions, on_delete: :delete_all), null: false
      add :test, :string, null: false
      add :verdict, :submission_verdict, null: false
      add :time_ms, :integer
      add :exit_code, :integer
    end

    create index(:test_results, [:submission_id])
  end
end
