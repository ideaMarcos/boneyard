# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.GameLive do
  use Phoenix.LiveView
  alias Boneyard.Cpu
  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.Tile

  defp is_playable_tile?(%Game{} = game, %Tile{} = tile) do
    tile in Game.playable_tiles(game)
  end

  defp has_playable_tiles?(%Game{} = game) do
    Game.playable_tiles(game) != []
  end

  defp tile_class(tile) do
    if Tile.is_double(tile) do
      "shadow"
    else
      "shadow"
    end
  end

  defp print_tiles([] = _tiles) do
    ""
  end

  defp print_tiles(tiles) do
    list =
      tiles
      |> Enum.map(fn x -> to_string(x) end)
      |> Enum.join("] [")

    ["[", list, "]"]
  end

  def mount(params, _session, socket) do
    game_id = Map.get(params, "id")
    _code = Map.get(params, "code")
    {:ok, game} = GameServer.get_game(game_id)
    {:ok, assign(socket, :game, game)}
  end

  def handle_event("finish_round", _params, socket) do
    Cpu.play_until_round_over(socket.assigns.game)
    |> case do
      # {:ok, _tile, game} ->
      #   {:noreply, update(socket, :game, fn _ -> game end)}

      {:error, :round_over, game} ->
        {:noreply, update(socket, :game, fn _ -> game end)}
    end
  end

  def handle_event("play_tile", %{"id" => tile_id}, socket) do
    {:ok, _tile, game} = Game.play_tile(socket.assigns.game, tile_id)
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_event("pass", _params, socket) do
    {:ok, game} = Game.pass(socket.assigns.game)
    {:noreply, update(socket, :game, fn _ -> game end)}
  end
end
