defmodule Phenom.Repo do
  use Ecto.Repo,
    otp_app: :phenom,
    adapter: Ecto.Adapters.Postgres
end
