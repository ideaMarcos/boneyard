defmodule Boneyard.Presence do
  use Phoenix.Presence, otp_app: :boneyard, pubsub_server: Boneyard.PubSub

  def fetch(game_id, presences) do
    {:ok, game} = Boneyard.GameServer.get_game(game_id)

    # TODO
    Enum.zip(game.player_codes, game.player_names)
    |> Enum.into(%{})

    # |> IO.inspect(label: "players")

    for {key, %{metas: metas}} <- presences, into: %{} do
      #   {key, %{metas: metas, user: users[String.to_integer(key)]}}
      {key, %{metas: metas}}
    end
  end
end
