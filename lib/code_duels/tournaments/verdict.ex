defmodule CodeDuels.Tournaments.Verdict do
  use Ecto.Type

  def type, do: :submission_verdict

  @values [
    :accepted,
    :wrong_answer,
    :time_limit,
    :memory_limit,
    :runtime_error,
    :compile_error,
    :runner_error,
    :unknown_lang
  ]

  def values, do: @values

  def cast(value) when value in @values, do: {:ok, value}

  def cast(value) when is_binary(value) do
    cast(String.to_existing_atom(value))
  rescue
    ArgumentError -> :error
  end

  def cast(_), do: :error

  def load("accepted"), do: {:ok, :accepted}
  def load("wrong_answer"), do: {:ok, :wrong_answer}
  def load("time_limit"), do: {:ok, :time_limit}
  def load("memory_limit"), do: {:ok, :memory_limit}
  def load("runtime_error"), do: {:ok, :runtime_error}
  def load("compile_error"), do: {:ok, :compile_error}
  def load("runner_error"), do: {:ok, :runner_error}
  def load("unknown_lang"), do: {:ok, :unknown_lang}

  def dump(:accepted), do: {:ok, "accepted"}
  def dump(:wrong_answer), do: {:ok, "wrong_answer"}
  def dump(:time_limit), do: {:ok, "time_limit"}
  def dump(:memory_limit), do: {:ok, "memory_limit"}
  def dump(:runtime_error), do: {:ok, "runtime_error"}
  def dump(:compile_error), do: {:ok, "compile_error"}
  def dump(:runner_error), do: {:ok, "runner_error"}
  def dump(:unknown_lang), do: {:ok, "unknown_lang"}
  def dump(_), do: :error
end
