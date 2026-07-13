defmodule CodeDuelsWeb.Helpers.TimeHelpers do
  def format_time(seconds) when seconds < 60, do: "#{seconds} сек"

  def format_time(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} мин #{remaining_seconds} сек"
  end

  def schedule_timer do
    Process.send_after(self(), :tick, 1000)
  end
end
