defmodule CodeDuels.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :hashed_password, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
  end
end
