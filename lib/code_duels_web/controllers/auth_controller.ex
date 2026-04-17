defmodule CodeDuelsWeb.AuthController do
  use CodeDuelsWeb, :controller

  alias CodeDuels.Accounts

  def new(conn, _params) do
    render(conn, :login)
  end

  def register_form(conn, _params) do
    render(conn, :register)
  end

  def create(conn, %{"username" => username, "password" => password}) do
    case Accounts.verify_password(username, password) do
      nil ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> redirect(to: "/login")

      user ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.name || user.username}!")
        |> redirect(to: "/")
    end
  end

  def create_user(conn, %{"username" => username, "password" => password}) do
    case Accounts.register_user(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome, #{user.name || user.username}!")
        |> redirect(to: "/")

      {:error, changeset} ->
        errors = for {field, {msg, _}} <- changeset.errors, do: "#{field}: #{msg}"

        conn
        |> put_flash(:error, Enum.join(errors, ", "))
        |> redirect(to: "/register")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully!")
    |> redirect(to: "/")
  end

  def profile(conn, _params) do
    user = conn.assigns.current_user

    if user do
      render(conn, :profile, user: user)
    else
      conn
      |> put_flash(:error, "Please log in to view your profile")
      |> redirect(to: "/login")
    end
  end

  def update_profile(conn, %{"username" => username}) do
    user = conn.assigns.current_user

    case Accounts.update_username(user, username) do
      {:ok, updated_user} ->
        conn
        |> put_flash(:info, "Profile updated!")
        |> assign(:current_user, updated_user)
        |> redirect(to: "/profile")

      {:error, changeset} ->
        errors = for {field, {msg, _}} <- changeset.errors, do: "#{field}: #{msg}"

        conn
        |> put_flash(:error, Enum.join(errors, ", "))
        |> render(:profile, user: user)
    end
  end
end
