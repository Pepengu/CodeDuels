defmodule CodeDuels.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias CodeDuels.Repo
  alias CodeDuels.Accounts.User

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("john")
      %User{}

      iex> get_user_by_username("unknown")
      nil
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by id.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user with username and password.

  ## Examples

      iex> register_user("john", "secret123")
      {:ok, %User{}}

      iex> register_user("john", "short")
      {:error, %Ecto.Changeset{}}
  """
  def register_user(username, password) do
    %User{}
    |> User.registration_changeset(%{username: username, hashed_password: password})
    |> Repo.insert()
  end

  @doc """
  Verifies username and password.

  Returns the user if credentials are valid, otherwise nil.

  ## Examples

      iex> verify_password("john", "secret123")
      %User{}

      iex> verify_password("john", "wrong")
      nil
  """
  def verify_password(username, password) when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)

    if user && User.verify_password(user, password) do
      user
    end
  end

  @doc """
  Updates the user's password.

  ## Examples

      iex> update_password(user, "oldpassword", "newpassword")
      {:ok, %User{}}

      iex> update_password(user, "wrongpassword", "newpassword")
      {:error, %Ecto.Changeset{}}
  """
  def update_password(user, old_password, new_password) do
    if User.verify_password(user, old_password) do
      user
      |> User.password_changeset(%{hashed_password: new_password})
      |> Repo.update()
    else
      {:error,
       %Ecto.Changeset{errors: [password: {"is invalid", validation: :incorrect_password}]}}
    end
  end

  @doc """
  Updates the user's username.

  ## Examples

      iex> update_username(user, "new_john")
      {:ok, %User{}}
  """
  def update_username(user, new_username) do
    user
    |> User.changeset(%{username: new_username})
    |> Repo.update()
  end

  def update_name(user, new_name) do
    user
    |> User.changeset(%{name: new_name})
    |> Repo.update()
  end
end
