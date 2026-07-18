defmodule Mix.Tasks.Typst.Compile do
  use Mix.Task

  @shortdoc "Compile Typst files to PDF and HTML"
  @moduledoc """
  Compiles regulations.typ to regulations.pdf and regulations.html
  in the priv/regulations/ directory.

  ## Examples

      mix typst.compile
  """

  @impl true
  def run(_args) do
    Mix.shell().info("Compiling regulations.typ...")

    case CodeDuels.Typst.compile() do
      :ok ->
        Mix.shell().info("  -> regulations.html")
        Mix.shell().info("  -> regulations.pdf")

      {:error, {format, err}} ->
        Mix.shell().error("Failed to compile #{format}: #{err}")
    end
  end
end
