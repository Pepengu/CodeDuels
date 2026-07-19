defmodule CodeDuels.TypstTest do
  use ExUnit.Case, async: true

  @moduletag :typst

  @regulations_html Path.expand("priv/regulations/regulations.html")
  @regulations_pdf Path.expand("priv/regulations/regulations.pdf")
  @cache_dir Path.expand("priv/regulations/cache")

  setup do
    on_exit(fn ->
      File.rm(@regulations_html)
      File.rm(@regulations_pdf)
    end)
  end

  describe "compile/0" do
    test "succeeds without args" do
      assert :ok = CodeDuels.Typst.compile()
    end

    test "produces valid HTML file" do
      :ok = CodeDuels.Typst.compile()
      html = File.read!(@regulations_html)
      assert html != ""
      assert html =~ "<html"
    end

    test "produces valid PDF file" do
      :ok = CodeDuels.Typst.compile()
      pdf = File.read!(@regulations_pdf)
      assert byte_size(pdf) > 0
      assert <<"%PDF"::binary, _::binary>> = pdf
    end
  end

  describe "compile_for_tournament/1" do
    setup do
      tournament = %{
        id: System.unique_integer([:positive]),
        name: "Test Tournament",
        rounds_amount: 5,
        round_time: 2400,
        intermission_time: 300,
        problems_per_round: 5,
        penalty: 10
      }

      cache = Path.expand(Path.join(@cache_dir, to_string(tournament.id)))

      on_exit(fn ->
        File.rm_rf(cache)
      end)

      {:ok, tournament: tournament, cache: cache}
    end

    test "succeeds with args", %{tournament: tournament} do
      assert :ok = CodeDuels.Typst.compile_for_tournament(tournament, [1, 1, 2, 2, 3])
    end

    test "produces valid HTML in cache", %{tournament: tournament, cache: cache} do
      :ok = CodeDuels.Typst.compile_for_tournament(tournament, [1, 1, 2, 2, 3])
      html = File.read!(Path.join(cache, "regulations.html"))
      assert html != ""
      assert html =~ "<html"
    end

    test "produces valid PDF in cache", %{tournament: tournament, cache: cache} do
      :ok = CodeDuels.Typst.compile_for_tournament(tournament, [1, 1, 2, 2, 3])
      pdf = File.read!(Path.join(cache, "regulations.pdf"))
      assert byte_size(pdf) > 0
      assert <<"%PDF"::binary, _::binary>> = pdf
    end
  end
end
