defmodule Boneyard.GameServerTest do
  use ExUnit.Case, async: true

  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.GameSupervisor
  alias Phoenix.PubSub

  setup do
    game_id = Game.new_game_id()
    {:ok, _pid} = GameSupervisor.start_game(game_id)
    PubSub.subscribe(Boneyard.PubSub, to_string(game_id))
    {:ok, game_id: game_id}
  end

  describe "get_game/1" do
    test "starts a new game server", %{game_id: game_id} do
      assert is_pid(GameServer.game_pid(game_id))
    end

    test "gets game state", %{game_id: game_id} do
      {:ok, game} = GameServer.get_game(game_id)
      assert game.id == game_id
      assert game.game_over? == false
    end

    test "handles non-existent games" do
      assert {:error, :game_not_found} = GameServer.get_game("==<>==")
    end
  end

  describe "add_player/2 and update_player_name/3" do
    test "add/update a player", %{game_id: game_id} do
      name = Enum.take_random(?a..?z, 5) |> to_string()
      {:ok, _} = GameServer.add_player(game_id, name)
      {:ok, game} = GameServer.get_game(game_id)
      assert_receive %{event: :player_added}
      assert name in game.player_names

      name = Enum.take_random(?a..?z, 5) |> to_string()
      {:ok, game} = GameServer.update_player_name(game_id, 0, name)
      assert_receive %{event: :game_updated}
      assert name in game.player_names
    end

    test "prevents duplicate player names", %{game_id: game_id} do
      {:ok, _} = GameServer.add_player(game_id, "p1")
      {:ok, _} = GameServer.add_player(game_id, "p2")

      assert {:error, :name_taken} = GameServer.update_player_name(game_id, 0, "p2")
    end
  end

  describe "play_tile/2" do
    test "plays a tile", %{game_id: game_id} do
      {:ok, _} = GameServer.add_player(game_id, "player1")
      {:ok, _} = GameServer.add_player(game_id, "player2")
      {:ok, game} = GameServer.get_game(game_id)
      tile = Game.playable_tiles(game) |> List.first()
      {:ok, ^tile, updated_game} = GameServer.play_tile(game_id, tile.id)

      first_tile = updated_game.line_of_play |> List.first()
      last_tile = updated_game.line_of_play |> List.last()
      assert tile in [first_tile, last_tile]
      assert_receive %{event: :game_updated}
    end
  end

  describe "game completion" do
    test "ends game", %{game_id: game_id} do
      {:ok, game} = GameServer.end_game(game_id)
      assert game.game_over? == true
    end
  end

  # describe "broadcasts" do
  #   test "broadcasts game updates", %{game_id: game_id} do
  #     GameServer.broadcast!(to_string(game_id), :test_event, %{data: "test"})
  #     assert_receive %{event: :test_event, payload: %{data: "test"}}
  #   end
  # end
end
