defmodule CodeDuels.Typst do
  @moduledoc """
  Compiles Typst source files to PDF and HTML.
  """

  @source "priv/regulations/regulations.typ"
  @base "priv/regulations"
  @cache_dir "priv/regulations/cache"

  def compile do
    source = Path.expand(@source)
    base = Path.expand(@base)

    with :ok <- compile_html(source, Path.join(base, "regulations.html"), []),
         :ok <- compile_pdf(source, Path.join(base, "regulations.pdf"), []) do
      :ok
    end
  end

  def compile_for_tournament(%{id: id, name: name} = tournament) do
    source = Path.expand(@source)
    cache = Path.expand(Path.join(@cache_dir, to_string(id)))

    with :ok <- check_typst(),
         :ok <- File.mkdir_p(cache) do
      inputs = [
        "--input",
        "tournament_name=#{name}",
        "--input",
        "rounds=#{tournament.rounds_amount}",
        "--input",
        "round_time=#{tournament.round_time}",
        "--input",
        "intermission_time=#{tournament.intermission_time}",
        "--input",
        "problems_per_round=#{tournament.problems_per_round}",
        "--input",
        "penalty=#{tournament.penalty}",
        "--input",
        "scores=#{Enum.join(tournament.scores || [1, 1, 2, 2, 3], ",")}"
      ]

      html_out = Path.join(cache, "regulations.html")
      pdf_out = Path.join(cache, "regulations.pdf")

      with :ok <- compile_html(source, html_out, inputs),
           :ok <- compile_pdf(source, pdf_out, inputs) do
        :ok
      end
    end
  end

  def cache_dir(tournament_id) do
    Path.expand(Path.join(@cache_dir, to_string(tournament_id)))
  end

  defp check_typst do
    if System.find_executable("typst"),
      do: :ok,
      else: {:error, :typst_not_found}
  end

  defp compile_html(source, output, extra_args) do
    case System.cmd("typst", ["compile", "--features", "html", source, output] ++ extra_args) do
      {_, 0} -> :ok
      {err, _} -> {:error, {:html, err}}
    end
  end

  defp compile_pdf(source, output, extra_args) do
    case System.cmd("typst", ["compile", source, output] ++ extra_args) do
      {_, 0} -> :ok
      {err, _} -> {:error, {:pdf, err}}
    end
  end
end
