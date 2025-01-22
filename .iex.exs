import ExUnit.Assertions
import IEx.Helpers

alias Boneyard.{
  Repo,
  Cpu,
  Game
}

import_if_available(Ecto.Query)
import_if_available(Ecto.Query, only: [from: 2])
import_if_available(Ecto.Changeset)
