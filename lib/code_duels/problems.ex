defmodule CodeDuels.Problems do
  @moduledoc """
  The Problem context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Problems.Problem
  alias CodeDuels.Repo
  # alias CodeDuels.Tournaments.{Tournament, Participant, Duel, Round}

  def get_problem!(id), do: Repo.get!(Problem, id)

  def get_tests(problem) do
    Path.join(problem.files_path, "tests/*")
    |> Path.wildcard()
    |> Enum.reject(&(Path.extname(&1) == ".a"))
    |> Enum.map(fn elem ->
      %{
        test: File.read!(elem),
        ans: File.read!(elem <> ".a")
      }
    end)
  end
end
