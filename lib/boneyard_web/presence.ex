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

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Boneyard.PubSub, topic)
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {topic, %{metas: [meta | _]}} ->
      {topic, meta}
    end)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))
    Phoenix.Component.assign(socket, presences: presences)
  end

  defp remove_presences(socket, leaves) do
    topics = Enum.map(leaves, fn {topic, _} -> topic end)
    presences = Map.drop(socket.assigns.presences, topics)
    Phoenix.Component.assign(socket, presences: presences)
  end

  def handle_diff(socket, presence_diff) do
    socket
    |> remove_presences(presence_diff.leaves)
    |> add_presences(presence_diff.joins)
  end
end
