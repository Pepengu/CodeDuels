defmodule CodeDuels.Problems do
  @moduledoc """
  The Problem context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Problems.Problem
  alias CodeDuels.Repo
  # alias CodeDuels.Tournaments.{Tournament, Participant, Duel, Round}

  def get_problem!(id), do: Repo.get!(Problem, id)
end
