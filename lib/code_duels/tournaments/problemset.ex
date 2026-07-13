defmodule CodeDuels.Tournaments.Problemset do
  @moduledoc """
  Functions for working with tournament problemsets.
  """

  @doc """
  Fetches problems by their IDs and maps them to labeled problem structs.
  Accepts a list of problem IDs (from `round.problemset`).
  Returns `[%{id: integer(), title: String.t(), letter: String.t()}]`.
  """
  @spec list_problems([integer()]) :: [%{id: integer(), title: String.t(), letter: String.t()}]
  def list_problems(problem_ids) when is_list(problem_ids) do
    problem_ids
    |> CodeDuels.Tournaments.get_problemset()
    |> Enum.map_reduce(?A, fn problem, acc ->
      {%{id: problem.id, title: problem.title, letter: <<acc>>}, acc + 1}
    end)
    |> elem(0)
  end

  @doc """
  Resolves a letter (e.g. "A", "B") to the problem ID at that index in the problemset.
  Returns the problem ID or nil if out of range.
  """
  @spec resolve_problem_id([integer()], String.t()) :: integer() | nil
  def resolve_problem_id(problemset, letter) when is_list(problemset) do
    index = letter_to_index(letter)

    if index >= 0 && index < length(problemset) do
      Enum.at(problemset, index)
    else
      nil
    end
  end

  @doc """
  Strips header elements and link tags from a problem statement HTML string.
  """
  @spec clean_statement_html(String.t()) :: String.t()
  def clean_statement_html(html) when is_binary(html) do
    doc =
      Floki.parse_document!(html)
      |> Floki.filter_out("[class~='header']")
      |> Floki.filter_out("link")

    Floki.raw_html(doc, encode: false)
  end

  defp letter_to_index(letter) do
    case letter |> String.upcase() |> String.to_charlist() |> hd() do
      c when c >= ?A and c <= ?Z -> c - ?A
      _ -> -1
    end
  end
end
