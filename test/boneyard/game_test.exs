defmodule Boneyard.GameTest do
  use ExUnit.Case, async: true
  alias Boneyard.Game

  setup _ do
    num_hands = Enum.random([2, 3, 4])
    num_tiles_per_hand = Enum.random([5, 7])
    max_tile_val = Enum.random([6, 9])
    {:ok, game} = Game.new(num_hands, num_tiles_per_hand, max_tile_val)
    %{game: game}
  end

  describe "Game - new" do
    test "new/3" do
      {:ok, game} = Game.new(4, 5, 6)

      assert game.num_hands === 4
      assert game.is_game_over === false
      assert game.line_of_play === []
      assert game.pass_count === 0
    end
  end

  describe "Game - passing" do
    test "pass/1", %{game: game} do
      assert {:ok, new_game} = Game.pass(game)
      assert new_game.pass_count === game.pass_count + 1
    end
  end

  describe "Game - play_tile" do
    test "play_tile_on_left_side/2", %{game: game} do
      assert {:ok, new_game} = Game.pass(game)
      [tile, _] = Enum.at(game.hands, game.active_hand)
      assert {:ok, new_game} = Game.play_tile_on_left_side(game, tile)
      assert new_game.pass_count === 0
    end
  end
end
