defmodule CodeDuelsWeb.LiveAuth do
  @moduledoc """
  Helper for mounting current_user in LiveViews.
  """

  def on_mount(:default, _params, session, socket) do
    user_id = Map.get(session, "user_id")
    user = user_id && CodeDuels.Accounts.get_user!(user_id)
    {:cont, Phoenix.Component.assign(socket, :current_user, user)}
  end
end
