defmodule Boneyard.Repo do
  use Ecto.Repo,
    otp_app: :boneyard,
    adapter: Ecto.Adapters.SQLite3
end
