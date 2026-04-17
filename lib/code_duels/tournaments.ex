defmodule CodeDuels.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Repo
  alias CodeDuels.Tournaments.Tournament

  def list_open_tournaments do
    Repo.all(from t in Tournament, where: t.is_open == true)
  end

  def get_tournament!(id), do: Repo.get!(Tournament, id)
end
