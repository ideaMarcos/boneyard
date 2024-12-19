# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.GameLive do
  use Phoenix.LiveView
  require Logger
  alias Boneyard.Cpu
  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.Tile

  defp can_take_from_boneyard?(%Game{} = game) do
    case Game.take_from_boneyard(game) do
      {:ok, _, _} -> true
      _ -> false
    end
  end

  defp is_playable_tile?(%Game{} = game, %Tile{} = tile) do
    tile in Game.playable_tiles(game)
  end

  defp has_playable_tiles?(%Game{} = game) do
    Game.playable_tiles(game) != []
  end

  defp tile_class(tile) do
    if Tile.is_double(tile) do
      "domino"
    else
      "domino horizontal"
    end
  end

  defp hand_class(%Game{} = game, hand_index) do
    if game.active_player == hand_index do
      "player-hand active"
    else
      "player-hand"
    end
  end

  def mount(params, _session, socket) do
    game_id = Map.get(params, "id")
    player_code = Map.get(params, "player_code")
    {:ok, game} = GameServer.get_game(game_id)
    # {:ok, _} = Boneyard.Presence.track(self(), game_id, player, %{})
    :ok = Phoenix.PubSub.subscribe(Boneyard.PubSub, game_id)

    player_index =
      Enum.find_index(game.player_codes, fn x -> x == player_code end) || -1

    {:ok,
     socket
     |> assign(:game, game)
     |> assign_new(:my_player_index, fn -> player_index end)
     |> assign(:my_player_code, player_code)}
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

  def handle_event("play_tile", %{"id" => tile_id, "side" => side}, socket) do
    result =
      case side do
        "left" -> GameServer.play_tile_on_left_side(socket.assigns.game.id, tile_id)
        "right" -> GameServer.play_tile_on_right_side(socket.assigns.game.id, tile_id)
        _ -> GameServer.play_tile(socket.assigns.game.id, tile_id)
      end

    case result do
      {:ok, _tile, game} -> {:noreply, update(socket, :game, fn _ -> game end)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("take_from_boneyard", _params, socket) do
    {:ok, _tile, game} = GameServer.take_from_boneyard(socket.assigns.game.id)
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_event("pass", _params, socket) do
    {:ok, game} = GameServer.pass(socket.assigns.game.id)
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_info(%{event: :players_updated, payload: game}, socket) do
    player_index =
      Enum.find_index(game.player_codes, fn x -> x == socket.assigns.my_player_code end)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    {:noreply, update(socket, :game, fn _ -> game end)}
  end
end
