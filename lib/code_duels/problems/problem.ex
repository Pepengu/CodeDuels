defmodule CodeDuels.Problems.Problem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "problems" do
    field :title, :string
    field :time_limit_ms, :integer
    field :memory_limit_kb, :integer
    field :statement, :string
    field :statement_lang, :string
    field :solutions, {:array, :map}
    field :checker, :string
    field :validator, :string
    field :files_path, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(problem, attrs) do
    problem
    |> cast(attrs, [
      :title,
      :time_limit_ms,
      :memory_limit_kb,
      :statement,
      :statement_lang,
      :solutions,
      :checker,
      :validator,
      :files_path
    ])
    |> validate_required([:title])
  end
end
