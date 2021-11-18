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

  describe "Game.new/3" do
    test "PASS with valid settings" do
      {:ok, game} = Game.new(4, 5, 6)

      assert game.num_hands === 4
      assert game.is_round_over === false
      assert game.line_of_play === []
      assert game.pass_count === 0
    end
  end

  describe "Game.pass/1" do
    test "PASS when no playable tiles", %{game: game1} do
      assert {:error, :no_playable_tiles, game2} = play_until_error(game1)
      assert Game.playable_tiles(game2) === []
      assert game2.pass_count === 0
      assert {:ok, game3} = Game.pass(game2)
      assert game3.active_hand === 0 or game3.active_hand > game2.active_hand
      assert game3.pass_count === game2.pass_count + 1
    end

    test "FAIL when playable tile available on first move of game", %{game: game1} do
      assert Game.playable_tiles(game1) !== []
      assert {:error, :must_use_playable_tiles, game2} = Game.pass(game1)
      assert game1 === game2
    end
  end

  defp play_until_error(game) do
    case Game.play_random_tile(game) do
      {:ok, new_game} ->
        play_until_error(new_game)

      error ->
        error
    end
  end

  describe "Game.play_tile/2" do
    test "PASS when playable tiles", %{game: game1} do
      tile =
        game1
        |> Game.playable_tiles()
        |> Enum.random()

      assert {:ok, game2} = Game.play_tile(game1, tile.id)
      assert game2.active_hand === 0 or game2.active_hand > game1.active_hand
      assert game2.pass_count === game1.pass_count
    end

    test "FAIL playing tile not in hand", %{game: game1} do
      assert {:ok, game2} = Game.play_random_tile(game1)
      [tile] = game2.line_of_play
      assert {:error, :tile_not_in_active_hand} = Game.play_tile(game2, tile.id)
    end
  end
end
