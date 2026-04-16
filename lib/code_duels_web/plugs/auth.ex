defmodule CodeDuelsWeb.Plugs.Auth do
  @moduledoc """
  Plug that fetches the current user from session and assigns to conn.
  """

  import Plug.Conn
  alias CodeDuels.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user!(user_id)
    assign(conn, :current_user, user)
  end
end
