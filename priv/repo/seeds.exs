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
import Ecto.Query

alias CodeDuels.Problems.Problem
alias CodeDuels.Problems.Importer
alias CodeDuels.Accounts.User
alias CodeDuels.Tournaments.Tournament
alias CodeDuels.Tournaments.Participant
alias CodeDuels.Tournaments.Duel

validate_folder = fn path ->
  xml_path = Path.join(path, "problem.xml")
  if File.exists?(xml_path), do: :ok, else: {:error, :missing_problem_xml}
end

import_folder = fn folder_path ->
  with :ok <- validate_folder.(folder_path),
       {:ok, metadata} <- Importer.parse_problem_xml(folder_path),
       attrs <- Importer.build_problem_attrs(metadata, folder_path) do
    %Problem{}
    |> Problem.changeset(attrs)
    |> Repo.insert()
  end
end

import_problems_from_folders = fn ->
  base_path = Path.join(Application.app_dir(:code_duels), "priv/uploads/problems")

  case File.ls(base_path) do
    {:ok, folders} ->
      Enum.each(folders, fn folder ->
        folder_path = Path.join(base_path, folder)

        if File.dir?(folder_path) and String.match?(folder, ~r/^\d+$/) do
          case Repo.get_by(Problem, files_path: folder_path) do
            nil ->
              case import_folder.(folder_path) do
                {:ok, _problem} ->
                  IO.puts("Imported problem: #{folder}")

                {:error, reason} ->
                  IO.puts("Failed to import problem #{folder}: #{inspect(reason)}")
              end

            _problem ->
              IO.puts("Problem #{folder} already exists, skipping")
          end
        end
      end)

    {:error, _} ->
      IO.puts("Problems folder does not exist yet")
  end
end

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

# Create 31 test users
test_users =
  for i <- 1..31 do
    username = "user#{i}"

    case Repo.get_by(User, username: username) do
      nil ->
        {:ok, user} =
          %User{}
          |> User.registration_changeset(%{
            username: username,
            name: "Тестовый Пользователь #{i}",
            hashed_password: "123123",
            is_admin: false
          })
          |> Repo.insert()

        IO.puts("Created user #{username}")
        user

      user ->
        IO.puts("User #{username} already exists")
        user
    end
  end

admin_user = Repo.get_by(User, username: "admin")
all_users = [admin_user | test_users]

# Create test tournament
tournament =
  case Repo.get_by(Tournament, name: "Тестовый турнир") do
    nil ->
      {:ok, tournament} =
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
      tournament

    t ->
      IO.puts("Test tournament already exists")
      t
  end

# Add all users as participants
for user <- all_users do
  case Repo.get_by(Participant, tournament_id: tournament.id, user_id: user.id) do
    nil ->
      {:ok, _} =
        %Participant{}
        |> Ecto.Changeset.change(%{
          tournament_id: tournament.id,
          user_id: user.id,
          score: 0.0,
          status: "active"
        })
        |> Repo.insert()

      IO.puts("Added #{user.username} to tournament")

    _ ->
      :skip
  end
end

# Generate duels for all rounds
current = tournament.current_round
total = tournament.rounds

existing_duels = Repo.aggregate(from(d in Duel, where: d.tournament_id == ^tournament.id), :count)
IO.puts("Current round: #{current}, target: #{total}, existing duels: #{existing_duels}")

if current < total or existing_duels == 0 do
  IO.puts("Generating duels...")

  active_participants =
    Repo.all(
      from p in Participant, where: p.tournament_id == ^tournament.id and p.status == "active"
    )
    |> Enum.sort_by(& &1.id)

  n = length(active_participants)
  half = div(n, 2)

  created =
    Enum.reduce(1..tournament.rounds, 0, fn round_num, acc ->
      pairs =
        Enum.reduce(1..half, [], fn i, acc_pairs ->
          top_idx = i - 1
          bottom_idx = n - (rem(i - 2 + round_num, half) + 1)
          p_a = Enum.at(active_participants, top_idx)
          p_b = Enum.at(active_participants, bottom_idx)
          [{p_a, p_b} | acc_pairs]
        end)
        |> Enum.reverse()

      Enum.each(pairs, fn {p_a, p_b} ->
        %Duel{}
        |> Duel.changeset(%{
          tournament_id: tournament.id,
          round_number: round_num,
          player_a_id: p_a.id,
          player_b_id: p_b.id,
          status: "pending",
          scores: []
        })
        |> Repo.insert!()
      end)

      IO.puts("Round #{round_num}: #{length(pairs)} duels")
      acc + length(pairs)
    end)

  IO.puts("Total duels: #{created}")

  tournament
  |> Ecto.Changeset.change(%{current_round: tournament.rounds, status: "completed"})
  |> Repo.update!()

  IO.puts("Seeding complete!")
else
  IO.puts("Tournament already seeded (round #{current})")
end

# Set sample scores for all duels
duels = Repo.all(from d in Duel, where: d.tournament_id == ^tournament.id)

problem_count = tournament.problems_per_round

for duel <- duels do
  scores =
    for _ <- 1..problem_count do
      roll = :rand.uniform(100)

      cond do
        roll <= 20 -> -:rand.uniform(20)
        roll <= 40 -> :rand.uniform(20)
        true -> 0
      end
    end

  duel
  |> Ecto.Changeset.change(%{status: "completed", scores: scores})
  |> Repo.update!()
end

IO.puts("Set sample scores for #{length(duels)} duels")

IO.puts("---")
IO.puts("Importing problems from folders...")

import_problems_from_folders.()

IO.puts("Seeding complete!")
