defmodule CodeDuelsWeb.PageController do
  use CodeDuelsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
