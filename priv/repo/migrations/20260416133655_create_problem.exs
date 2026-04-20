defmodule CodeDuels.Repo.Migrations.CreateProblem do
  use Ecto.Migration

  def change do
    create table(:problems) do
      add :title, :string
      add :time_limit_ms, :integer
      add :memory_limit_kb, :integer
      add :statement, :text
      add :statement_lang, :string
      add :solutions, {:array, :map}
      add :checker, :text
      add :validator, :text
      add :files_path, :string

      timestamps(type: :utc_datetime)
    end
  end
end
