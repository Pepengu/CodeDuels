defmodule CodeDuels.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :name, :string
    field :hashed_password, :string
    field :is_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :name, :hashed_password, :is_admin])
    |> validate_required(:username)
    |> validate_length(:username, min: 3, max: 32)
    |> validate_length(:name, min: 1, max: 50)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "must contain only letters, numbers, and underscores"
    )
    |> unique_constraint(:username)
  end

  def registration_changeset(user, attrs) do
    changeset(user, attrs)
    |> validate_required(:hashed_password)
    |> validate_length(:hashed_password, min: 6)
    |> put_hashed_password()
  end

  defp put_hashed_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{hashed_password: password}} ->
        put_change(changeset, :hashed_password, Bcrypt.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:hashed_password])
    |> validate_required(:hashed_password)
    |> validate_length(:hashed_password, min: 6)
    |> put_hashed_password()
  end

  def verify_password(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(password) do
    Bcrypt.verify_pass(password, hashed_password)
  end
end
