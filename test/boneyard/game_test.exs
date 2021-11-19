defmodule Boneyard.GameTest do
  use ExUnit.Case, async: true
  alias Boneyard.Game
  alias Boneyard.Tile

  setup _ do
    num_hands = Enum.random([2, 3, 4])
    num_tiles_per_hand = Enum.random([5, 7])
    max_tile_val = Enum.random([6, 9])
    {:ok, game} = Game.new(num_hands, num_tiles_per_hand, max_tile_val)
    {:ok, game_476} = Game.new(4, 7, 6)
    %{game: game, game_476: game_476}
  end

  describe "Game.new/3" do
    test "PASS with valid settings" do
      {:ok, game} = Game.new(4, 5, 6)

      assert game.num_hands === 4
      assert game.line_of_play === []
      assert game.is_round_over === false
      assert game.is_game_over === false
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

  describe "Game.play_tile/2" do
    test "PASS playing tile in hand", %{game: game1} do
      player_tile =
        game1
        |> Game.playable_tiles()
        |> Enum.random()

      active_hand = Enum.at(game1.hands, game1.active_hand)
      assert tile_in_hand(active_hand, player_tile) === true
      assert {:ok, game2} = Game.play_tile(game1, player_tile.id)
      assert game2.active_hand === 0 or game2.active_hand > game1.active_hand
      assert game2.pass_count === game1.pass_count
      assert game2.line_of_play === [player_tile]
      assert tile_in_any_hand(game2.hands, player_tile) === false
    end

    test "FAIL playing tile not in hand", %{game: game1} do
      assert {:ok, game2} = Game.play_random_tile(game1)
      [tile] = game2.line_of_play
      assert {:error, :tile_not_in_active_hand} = Game.play_tile(game2, tile.id)
    end

    test "PASS playing on left side", %{game_476: game1} do
      line_tile = Tile.new(61)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile_on_left_side(game2, 66)
      assert game3.line_of_play === [Tile.new(66), line_tile]
    end

    test "PASS playing on right side", %{game_476: game1} do
      line_tile = Tile.new(62) |> Tile.switch_sides()
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile_on_right_side(game2, 66)
      assert game3.line_of_play === [line_tile, Tile.new(66)]
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

  defp tile_in_any_hand(hands, tile) do
    Enum.any?(hands, &tile_in_hand(&1, tile))
  end

  defp tile_in_hand(hand, tile) do
    Enum.any?(hand, &Tile.===(&1, tile))
  end
end
