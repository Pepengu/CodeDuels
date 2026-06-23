defmodule CodeDuelsWeb.ProblemFileController do
  use CodeDuelsWeb, :controller

  alias CodeDuels.Tournaments
  alias CodeDuels.Problems

  # Security note: This code assumes there is no information in the statement
  # folder that the user should not have access to. Only files co-located with
  # the problem.html in the statement directory are served. Path traversal
  # attempts (../) are blocked by Path.expand + String.starts_with? check.
  def serve_statement_file(conn, %{
        "tournament_id" => tid,
        "round_number" => rn,
        "filename" => filename
      }) do
    round_num = String.to_integer(rn)
    round = Tournaments.get_round(tid, round_num)

    result =
      Enum.find_value(round.problemset || [], fn pid ->
        problem = Problems.get_problem!(pid)

        if problem.statement do
          statement_dir = problem.statement |> Path.dirname() |> Path.expand()
          full_path = Path.join(statement_dir, filename) |> Path.expand()

          if String.starts_with?(full_path, statement_dir) && File.exists?(full_path) do
            full_path
          end
        end
      end)

    if result do
      conn
      |> put_resp_content_type(MIME.from_path(result))
      |> send_file(200, result)
    else
      send_resp(conn, 404, "not found")
    end
  end
end
