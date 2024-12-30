defmodule Boneyard.GameGarbageCollectorTest do
  use ExUnit.Case, async: false

  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.GameSupervisor
  alias Boneyard.GameGarbageCollector

  setup do
    # Start a new game for each test
    game_id = Game.new_game_id()
    {:ok, _pid} = GameSupervisor.start_game(game_id)
    {:ok, game_id: game_id}
  end

  describe "garbage collection" do
    test "stops completed games", %{game_id: game_id} do
      {:ok, _} = GameServer.get_game(game_id)

      # :sys.replace_state(GameServer.game_pid(game_id), fn _state ->
      #   %{game: %{game_over?: true}}
      # end)
      {:ok, _} = GameServer.end_game(game_id)

      assert :ok == Process.send(GameGarbageCollector, :work, [])
      Process.sleep(100)

      # Verify the game process was stopped
      assert GameServer.game_pid(game_id) == nil
    end

    test "keeps active games running", %{game_id: game_id} do
      # Get the initial game pid
      game_pid = GameServer.game_pid(game_id)

      assert :ok == Process.send(GameGarbageCollector, :work, [])
      Process.sleep(100)

      # Verify the game is still running
      assert GameServer.game_pid(game_id) == game_pid
      assert Process.alive?(game_pid)
    end

    test "handles multiple games correctly" do
      game_ids =
        for _ <- 1..3 do
          game_id = Game.new_game_id()
          {:ok, _pid} = GameSupervisor.start_game(game_id)
          game_id
        end

      # Mark the second game as completed
      [_active1, completed, active2] = game_ids
      {:ok, game} = GameServer.get_game(completed)
      {:ok, _} = GameServer.end_game(game.id)

      assert :ok == Process.send(GameGarbageCollector, :work, [])
      Process.sleep(100)

      # Verify only the completed game was stopped
      assert GameServer.game_pid(List.first(game_ids)) != nil
      assert GameServer.game_pid(completed) == nil
      assert GameServer.game_pid(active2) != nil
    end
  end
end
