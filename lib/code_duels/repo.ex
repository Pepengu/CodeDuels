defmodule CodeDuels.Repo do
  use Ecto.Repo,
    otp_app: :code_duels,
    adapter: Ecto.Adapters.Postgres
end
