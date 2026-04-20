defmodule Mix.Tasks.Problems.Import do
  use Mix.Task
  alias CodeDuels.Problems.Importer

  @shortdoc "Import a Codeforces Polygon problem package"
  @moduledoc """
  Import a problem from a ZIP file or Polygon URL.

  ## Examples

      mix problems.import /path/to/problem.zip
      mix problems.import https://polygon.codeforces.com/p6utdCe/Pepengu/comp-prog-exam
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [] ->
        Mix.shell().error("Please provide a path or URL to import")
        Mix.shell().info("Usage: mix problems.import <path_or_url>")

      [path_or_url] ->
        import_problem(path_or_url)
    end
  end

  defp import_problem(path) do
    Mix.shell().info("Importing problem from: #{path}")

    result =
      if String.starts_with?(path, "http://") or String.starts_with?(path, "https://") do
        Importer.import_from_url(path)
      else
        Importer.import_from_zip(path)
      end

    case result do
      {:ok, problem} ->
        IO.puts("Successfully imported problem!")
        IO.puts("Title: #{problem.title}")
        IO.puts("ID: #{problem.id}")
        IO.puts("Files: #{problem.files_path}")

      {:error, reason} ->
        Mix.shell().error("Failed to import problem: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
