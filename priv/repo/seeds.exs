# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CodeDuels.Repo.insert!(%CodeDuels.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CodeDuels.Repo
alias CodeDuels.Accounts.User
alias CodeDuels.Tournaments.Tournament

# Create admin user
if Repo.get_by(User, username: "admin") do
  IO.puts("Admin user already exists")
else
  {:ok, _admin} =
    %User{}
    |> User.registration_changeset(%{
      username: "admin",
      name: "Админ Адимнович Админов",
      hashed_password: "123123",
      is_admin: true
    })
    |> Repo.insert()

  IO.puts("Created admin user")
end

# Create test tournament
if Repo.get_by(Tournament, name: "Тестовый турнир") do
  IO.puts("Test tournament already exists")
else
  {:ok, _tournament} =
    %Tournament{}
    |> Tournament.changeset(%{
      name: "Тестовый турнир",
      rounds: 5,
      problems_per_round: 5,
      round_time: 2400,
      intermission_time: 300,
      penality: 5,
      scores: [1, 1, 2, 2, 3],
      max_participants: 32,
      is_open: true,
      start_time: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()

  IO.puts("Created test tournament")
end

IO.puts("Seeding complete!")
