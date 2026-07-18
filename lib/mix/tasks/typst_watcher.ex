defmodule Mix.Tasks.TypstWatcher do
  @moduledoc """
  A GenServer that watches priv/regulations/ for .typ file changes
  and recompiles regulations.typ when modifications are detected.

  Used as a Phoenix dev watcher.
  """
  use GenServer

  require Logger

  @compile {:no_warn_undefined, FileSystem}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    path = Path.expand("priv/regulations")

    unless File.dir?(path) do
      Mix.raise("priv/regulations directory not found")
    end

    {:ok, watcher} = FileSystem.start_link(dirs: [path])
    FileSystem.subscribe(watcher)
    Logger.info("TypstWatcher: watching #{path} for changes")
    {:ok, %{watcher: watcher}}
  end

  @impl true
  def handle_info({:file_event, _watcher, {path, events}}, state) do
    if String.ends_with?(path, ".typ") and :modified in events do
      Logger.info("TypstWatcher: regulations.typ changed, recompiling...")
      CodeDuels.Typst.compile()
    end

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
