defmodule CodeDuelsWeb.PageController do
  use CodeDuelsWeb, :controller

  def home(conn, _params) do
    IO.puts(conn)
    #if Map.get(session, "user_id") == nil do
    #  conn |> redirect("/login")
    #end
    render(conn, :home)
  end
end
