defmodule CodeDuels.Tournaments.SubmissionStatus do
  use Ecto.Type

  def type, do: :submission_status

  @values [:pending, :testing, :done, :failed]

  def cast(value) when value in @values, do: {:ok, value}
  def cast(value) when is_binary(value), do: cast(String.to_existing_atom(value))
  def cast(_), do: :error

  def load("pending"), do: {:ok, :pending}
  def load("testing"), do: {:ok, :testing}
  def load("done"), do: {:ok, :done}
  def load("failed"), do: {:ok, :failed}

  def dump(:pending), do: {:ok, "pending"}
  def dump(:testing), do: {:ok, "testing"}
  def dump(:done), do: {:ok, "done"}
  def dump(:failed), do: {:ok, "failed"}
  def dump(_), do: :error
end
