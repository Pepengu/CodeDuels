defmodule CodeDuels.Tournaments.RoundState do
  @moduledoc """
  Computes time-based round state: lock status, countdown timers, timestamps.
  """

  defstruct [
    :locked,
    :time_based_locked,
    :time_remaining,
    :round_unlock_time,
    :round_end_time,
    :now,
    :unlock_ts,
    :end_ts
  ]

  @spec compute(map(), integer(), boolean()) :: %__MODULE__{}
  def compute(tournament, round_num, is_admin) do
    now = DateTime.utc_now()
    round_unlock_time = CodeDuels.Tournaments.round_unlock_time(tournament, round_num)

    round_end_time =
      if round_unlock_time,
        do: DateTime.add(round_unlock_time, tournament.round_time, :second),
        else: nil

    time_based_locked = round_unlock_time && DateTime.compare(now, round_unlock_time) == :lt
    locked = time_based_locked && !is_admin
    time_remaining = calculate_time_remaining(now, round_end_time, round_unlock_time)
    unlock_ts = round_unlock_time && DateTime.to_unix(round_unlock_time)
    end_ts = round_end_time && DateTime.to_unix(round_end_time)

    %__MODULE__{
      locked: locked,
      time_based_locked: time_based_locked,
      time_remaining: time_remaining,
      round_unlock_time: round_unlock_time,
      round_end_time: round_end_time,
      now: now,
      unlock_ts: unlock_ts,
      end_ts: end_ts
    }
  end

  defp calculate_time_remaining(now, round_end_time, round_unlock_time) do
    cond do
      round_unlock_time == nil ->
        ""

      DateTime.compare(now, round_unlock_time) == :lt ->
        diff = DateTime.diff(round_unlock_time, now)
        "До начала #{format_seconds(diff)}"

      round_end_time && DateTime.compare(now, round_end_time) == :lt ->
        diff = DateTime.diff(round_end_time, now)
        format_seconds(diff)

      round_end_time && DateTime.compare(now, round_end_time) == :gt ->
        "Завершён"

      true ->
        "0 сек"
    end
  end

  defp format_seconds(seconds) when seconds < 60, do: "#{seconds} сек"

  defp format_seconds(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} мин #{remaining_seconds} сек"
  end
end
