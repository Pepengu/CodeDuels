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
alias CodeDuels.Tournaments
alias CodeDuels.Tournaments.Tournament
alias CodeDuels.Tournaments.Participant
alias CodeDuels.Tournaments.Duel
alias CodeDuels.Tournaments.Round
alias CodeDuels.Tournaments.Submission

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
      folders
      |> Enum.filter(&(File.dir?(Path.join(base_path, &1)) and String.match?(&1, ~r/^\d+$/)))
      |> Enum.sort_by(&String.to_integer/1)
      |> Enum.each(fn folder ->
        folder_path = Path.join(base_path, folder)

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
      end)

    {:error, _} ->
      IO.puts("Problems folder does not exist yet")
  end
end

# Helper: generate 10-element duel scores for `problem_count` problems.
# Format: [pa_p1, pb_p1, pa_p2, pb_p2, ...]
#   negative value at even index  = player_a solved (penalty = abs)
#   positive value at odd index   = player_b solved (penalty = value)
#   zero                          = unsolved
gen_duel_scores = fn problem_count ->
  Enum.flat_map(1..problem_count, fn _ ->
    for _ <- 1..2 do
      roll = :rand.uniform(100)

      cond do
        roll <= 45 -> -:rand.uniform(20)
        roll <= 90 -> :rand.uniform(20)
        true -> 0
      end
    end
  end)
end

# Helper: create submissions for a single duel's problem results.
# `results` is a list of {problem_id, problem_letter, solved_a?, solved_b?}
create_duel_submissions = fn round, results, user_a, user_b ->
  languages =
    Application.compile_env(:code_duels, :runner)[:adapter].languages()
    |> Enum.map(fn {key, _display} -> to_string(key) end)

  make_sub = fn user, problem_id, letter, solved, lang ->
    verdict =
      if solved do
        :accepted
      else
        Enum.random([:wrong_answer, :time_limit, :runtime_error, :memory_limit])
      end

    %Submission{}
    |> Submission.changeset(%{
      user_id: user.id,
      round_id: round.id,
      problem_id: problem_id,
      language: lang,
      code:
        "#include <bits/stdc++.h>\nusing namespace std;\nint main() { /* #{letter} */ return 0; }",
      status: :done,
      problem_letter: letter,
      verdict: verdict,
      message: if(solved, do: "OK", else: "Wrong answer on test 3"),
      tests_passed: if(solved, do: 10, else: :rand.uniform(9))
    })
    |> Repo.insert!()
  end

  for {problem_id, letter, solved_a, solved_b} <- results do
    # player_a submissions
    if solved_a do
      # a couple of wrong attempts then accepted
      for _ <- 1..:rand.uniform(2) do
        make_sub.(user_a, problem_id, letter, false, Enum.random(languages))
      end

      make_sub.(user_a, problem_id, letter, true, Enum.random(languages))
    else
      for _ <- 1..:rand.uniform(2) do
        make_sub.(user_a, problem_id, letter, false, Enum.random(languages))
      end
    end

    # player_b submissions
    if solved_b do
      for _ <- 1..:rand.uniform(2) do
        make_sub.(user_b, problem_id, letter, false, Enum.random(languages))
      end

      make_sub.(user_b, problem_id, letter, true, Enum.random(languages))
    else
      for _ <- 1..:rand.uniform(2) do
        make_sub.(user_b, problem_id, letter, false, Enum.random(languages))
      end
    end
  end
end

# Helper: seed one tournament fully.
seed_tournament = fn tournament, rounds_amount, problems_per_round, participants, rounds ->
  # rounds already created with problemset above; ensure they exist
  problem_letters = Enum.map(?A..?Z, &<<&1>>)

  # Create duels round-robin within participants
  n = length(participants)
  half = div(n, 2)

  all_duels =
    Enum.reduce(1..rounds_amount, [], fn round_num, acc ->
      pairs =
        Enum.reduce(1..half, [], fn i, acc_pairs ->
          top_idx = i - 1
          bottom_idx = n - (rem(i - 2 + round_num, half) + 1)
          p_a = Enum.at(participants, top_idx)
          p_b = Enum.at(participants, bottom_idx)
          [{p_a, p_b} | acc_pairs]
        end)
        |> Enum.reverse()

      round_duels =
        Enum.map(pairs, fn {p_a, p_b} ->
          %Duel{}
          |> Duel.changeset(%{
            tournament_id: tournament.id,
            round_number: round_num,
            player_a_id: p_a.id,
            player_b_id: p_b.id,
            status: "completed",
            scores: gen_duel_scores.(problems_per_round)
          })
          |> Repo.insert!()
        end)

      acc ++ round_duels
    end)

  # For each duel, build submissions + compute participant score contributions
  scores_contrib =
    Enum.reduce(all_duels, %{}, fn duel, acc ->
      round = Enum.find(rounds, &(&1.round_number == duel.round_number))
      problemset = round.problemset
      scores = duel.scores

      # decode results per problem
      results =
        Enum.map(0..(problems_per_round - 1), fn i ->
          a_idx = i * 2
          b_idx = i * 2 + 1
          a_val = Enum.at(scores, a_idx) || 0
          b_val = Enum.at(scores, b_idx) || 0

          solved_a = a_val < 0
          solved_b = b_val > 0

          problem_id = Enum.at(problemset, i)
          letter = Enum.at(problem_letters, i)

          {problem_id, letter, solved_a, solved_b}
        end)

      create_duel_submissions.(
        round,
        results,
        Repo.get!(Participant, duel.player_a_id) |> Repo.preload(:user) |> Map.get(:user),
        Repo.get!(Participant, duel.player_b_id) |> Repo.preload(:user) |> Map.get(:user)
      )

      # compute match score per player using same logic as Standings
      round_record = Repo.get!(Round, round.id)
      round_scores = round_record.scores || [1, 1, 2, 2, 3]

      {a_score, _, _} =
        Tournaments.Standings.calculate_player_score(scores, true, round_scores)

      {b_score, _, _} =
        Tournaments.Standings.calculate_player_score(scores, false, round_scores)

      acc
      |> Map.update(duel.player_a_id, a_score, &(&1 + a_score))
      |> Map.update(duel.player_b_id, b_score, &(&1 + b_score))
    end)

  # apply participant scores
  Enum.each(scores_contrib, fn {pid, score} ->
    participant = Repo.get!(Participant, pid)
    participant |> Ecto.Changeset.change(%{score: score / 1.0}) |> Repo.update!()
  end)

  tournament
  |> Ecto.Changeset.change(%{current_round: rounds_amount, status: "completed"})
  |> Repo.update!()

  IO.puts(
    "Seeded tournament '#{tournament.name}' with #{length(all_duels)} duels, #{length(participants)} participants"
  )
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

# Import problems BEFORE creating rounds so problemset references real IDs
import_problems_from_folders.()
problem_ids = Repo.all(from p in Problem, order_by: p.id, select: p.id)
IO.puts("Available problems: #{inspect(problem_ids)}")

# ===== Tournament 1: Тестовый турнир (5 rounds, 5 problems) =====
tournament1 =
  case Repo.get_by(Tournament, name: "Тестовый турнир") do
    nil ->
      {:ok, t} =
        Tournaments.create_tournament(%{
          name: "Тестовый турнир",
          rounds_amount: 5,
          problems_per_round: 5,
          round_time: 2400,
          intermission_time: 300,
          penalty: 5,
          max_participants: 32,
          is_open: true,
          start_time:
            DateTime.utc_now() |> DateTime.add(5 * 60, :second) |> DateTime.truncate(:second)
        })

      IO.puts("Created test tournament 1")
      t

    t ->
      IO.puts("Test tournament 1 already exists")
      t
  end

# Ensure rounds exist for tournament1
existing_rounds1 =
  Repo.all(from r in Round, where: r.tournament_id == ^tournament1.id)

_rounds1 =
  if length(existing_rounds1) == 0 do
    t1_scores = [1, 1, 2, 2, 3]

    rounds =
      for round_num <- 1..tournament1.rounds_amount do
        %Round{}
        |> Round.changeset(%{
          tournament_id: tournament1.id,
          round_number: round_num,
          problemset: Enum.take(problem_ids, tournament1.problems_per_round),
          start_time: ~T[00:00:00],
          scores: t1_scores
        })
        |> Repo.insert!()
      end

    IO.puts("Created #{tournament1.rounds_amount} rounds for tournament1")
    rounds
  else
    rounds =
      Enum.map(existing_rounds1, fn round ->
        round
        |> Ecto.Changeset.change(%{
          problemset: Enum.take(problem_ids, tournament1.problems_per_round)
        })
        |> Repo.update!()
      end)

    IO.puts("Updated rounds for tournament1")
    rounds
  end

# Participants for tournament1: admin=organizer, rest=participant
for user <- all_users do
  case Repo.get_by(Participant, tournament_id: tournament1.id, user_id: user.id) do
    nil ->
      role = if(user.is_admin, do: "organizer", else: "participant")

      {:ok, _} =
        %Participant{}
        |> Ecto.Changeset.change(%{
          tournament_id: tournament1.id,
          user_id: user.id,
          score: 0.0,
          role: role
        })
        |> Repo.insert()

      IO.puts("Added #{user.username} to tournament1 as #{role}")

    _ ->
      :skip
  end
end

participants1 = Repo.all(from p in Participant, where: p.tournament_id == ^tournament1.id)

# Tournament1 is "upcoming" — no duels seeded, status stays "setup"

# ===== Tournament 2: Зимний кубок (3 rounds, 3 problems) — closed, visible only to admins & participants =====
tournament2 =
  case Repo.get_by(Tournament, name: "Зимний кубок") do
    nil ->
      {:ok, t} =
        Tournaments.create_tournament(%{
          name: "Зимний кубок",
          rounds_amount: 3,
          problems_per_round: 3,
          round_time: 1800,
          intermission_time: 240,
          penalty: 5,
          max_participants: 16,
          is_open: false,
          start_time: DateTime.utc_now() |> DateTime.add(-14 * 24 * 3600, :second)
        })

      IO.puts("Created test tournament 2")
      t

    t ->
      IO.puts("Test tournament 2 already exists")
      t
  end

# Ensure rounds exist for tournament2
existing_rounds2 =
  Repo.all(from r in Round, where: r.tournament_id == ^tournament2.id)

rounds2 =
  if length(existing_rounds2) == 0 do
    t2_scores = [1, 2, 3]

    rounds =
      for round_num <- 1..tournament2.rounds_amount do
        %Round{}
        |> Round.changeset(%{
          tournament_id: tournament2.id,
          round_number: round_num,
          problemset: Enum.take(problem_ids, tournament2.problems_per_round),
          start_time: ~T[00:00:00],
          scores: t2_scores
        })
        |> Repo.insert!()
      end

    IO.puts("Created #{tournament2.rounds_amount} rounds for tournament2")
    rounds
  else
    rounds =
      Enum.map(existing_rounds2, fn round ->
        round
        |> Ecto.Changeset.change(%{
          problemset: Enum.take(problem_ids, tournament2.problems_per_round)
        })
        |> Repo.update!()
      end)

    IO.puts("Updated rounds for tournament2")
    rounds
  end

# Participants for tournament2: subset of users (admin + 11 test users)
t2_users = Enum.take(all_users, 12)

for user <- t2_users do
  case Repo.get_by(Participant, tournament_id: tournament2.id, user_id: user.id) do
    nil ->
      role = if(user.is_admin, do: "organizer", else: "participant")

      {:ok, _} =
        %Participant{}
        |> Ecto.Changeset.change(%{
          tournament_id: tournament2.id,
          user_id: user.id,
          score: 0.0,
          role: role
        })
        |> Repo.insert()

      IO.puts("Added #{user.username} to tournament2 as #{role}")

    _ ->
      :skip
  end
end

participants2 = Repo.all(from p in Participant, where: p.tournament_id == ^tournament2.id)

# Seed tournament2 only if it has no duels yet
existing_duels2 =
  Repo.aggregate(from(d in Duel, where: d.tournament_id == ^tournament2.id), :count)

if existing_duels2 == 0 do
  seed_tournament.(
    tournament2,
    tournament2.rounds_amount,
    tournament2.problems_per_round,
    participants2,
    rounds2
  )
else
  IO.puts("Tournament2 already has duels, skipping reseed")
end

# Link present avatar files to their users.
# Files in priv/uploads/avatars follow the naming "avatars/{user_id}-{unix_ts}.webp".
# We link each user to their most recent avatar file (idempotent).
link_avatars = fn ->
  avatars_dir = Path.join(Application.app_dir(:code_duels), "priv/uploads/avatars")

  case File.ls(avatars_dir) do
    {:ok, files} ->
      files
      |> Enum.filter(&String.ends_with?(&1, ".webp"))
      |> Enum.map(fn filename ->
        user_id =
          filename
          |> String.split("-")
          |> List.first()
          |> Integer.parse()
          |> case do
            {id, _} -> id
            :error -> nil
          end

        {user_id, filename}
      end)
      |> Enum.reject(fn {user_id, _} -> is_nil(user_id) end)
      |> Enum.group_by(fn {user_id, _} -> user_id end, fn {_, filename} -> filename end)
      |> Enum.each(fn {user_id, filenames} ->
        latest =
          Enum.max_by(filenames, fn filename ->
            ts =
              filename
              |> String.split("-")
              |> List.last()
              |> String.trim_trailing(".webp")

            String.to_integer(ts)
          end)

        avatar_path = "avatars/" <> latest

        case Repo.get(User, user_id) do
          nil ->
            IO.puts("Avatar #{latest} references unknown user #{user_id}, skipping")

          user ->
            Repo.update!(Ecto.Changeset.change(user, %{avatar_path: avatar_path}))
            IO.puts("Linked avatar #{latest} to user #{user_id}")
        end
      end)

    {:error, _} ->
      IO.puts("Avatars folder does not exist yet")
  end
end

link_avatars.()

IO.puts("Seeding complete!")
