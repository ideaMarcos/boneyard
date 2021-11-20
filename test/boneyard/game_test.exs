defmodule Boneyard.GameTest do
  use ExUnit.Case, async: true
  alias Boneyard.Game
  alias Boneyard.Tile

  setup _ do
    num_hands = Enum.random(2..4)
    num_tiles_per_hand = Enum.random([5, 7])
    max_tile_val = Enum.random([6, 9])
    {:ok, game} = Game.new(num_hands, num_tiles_per_hand, max_tile_val)
    {:ok, game_476} = Game.new(4, 7, 6)
    {:ok, game_356} = Game.new(3, 5, 6)
    %{game: game, game_476: game_476, game_356: game_356}
  end

  describe "Game.new/3" do
    test "PASS with valid settings" do
      num_hands = Enum.random([2, 3, 4])
      num_tiles_per_hand = Enum.random([5, 7])
      max_tile_val = Enum.random([6, 9])
      assert {:ok, game} = Game.new(num_hands, num_tiles_per_hand, max_tile_val)

      assert game.num_hands === num_hands
      assert length(game.hands) === game.num_hands
      assert Enum.all?(game.hands, fn hand -> length(hand) === game.num_tiles_per_hand end)
      assert length(game.scores) === game.num_hands
      assert Enum.all?(game.scores, fn score -> score === 0 end)
      assert game.num_tiles_per_hand === num_tiles_per_hand
      assert game.max_tile_val === max_tile_val
      assert game.line_of_play === []
      assert game.is_round_over === false
      assert game.is_game_over === false
      assert is_nil(game.last_player)
    end

    test "FAIL not enough tiles" do
      assert {:error, :not_enough_tiles} = Game.new(6, 7, 6)
    end
  end

  describe "Game.pass/1" do
    test "PASS when no playable tiles", %{game_476: game1} do
      assert {:error, :no_playable_tiles, game2} = play_until_error(game1)
      assert Game.playable_tiles(game2) === []
      assert is_nil(game2.last_player) === false
      assert game2.boneyard === []
      assert {:ok, game3} = Game.pass(game2)
      assert game3.active_player === 0 or game3.active_player > game2.active_player
      assert game3.last_player === game2.last_player
    end

    test "FAIL when playable tile available", %{game_476: game1} do
      assert Game.playable_tiles(game1) !== []
      assert {:error, :must_use_playable_tiles, game2} = Game.pass(game1)
      assert game1 === game2
    end

    test "FAIL when boneyard not empty", %{game_356: game1} do
      assert {:error, :no_playable_tiles, game2} = play_until_error(game1)
      assert game2.boneyard !== []
      assert {:error, :boneyard_not_empty, game3} = Game.pass(game2)
      assert game2 === game3
    end
  end

  describe "Game.play_random_tile/1" do
    test "PASS playing tile in hand", %{game: game1} do
      assert {:ok, game2} = Game.play_random_tile(game1)
      assert game2.last_player === game1.active_player
      assert [player_tile] = game2.line_of_play
      assert tile_in_any_hand(game2.hands, player_tile) === false
      active_player = Enum.at(game1.hands, game1.active_player)
      assert tile_in_hand(active_player, player_tile) === true
    end
  end

  describe "Game.play_tile/2" do
    test "PASS playing tile in hand", %{game: game1} do
      player_tile =
        game1
        |> Game.playable_tiles()
        |> Enum.random()

      active_player = Enum.at(game1.hands, game1.active_player)
      assert tile_in_hand(active_player, player_tile) === true
      assert {:ok, game2} = Game.play_tile(game1, player_tile.id)
      assert game2.active_player === 0 or game2.active_player > game1.active_player
      assert game2.last_player === game1.active_player
      assert game2.line_of_play === [player_tile]
      assert tile_in_any_hand(game2.hands, player_tile) === false
    end

    test "PASS playing on left side", %{game_476: game1} do
      line_tile = Tile.new(61)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile(game2, 66)
      assert game3.line_of_play === [Tile.new(66), line_tile]
    end

    test "PASS playing on right side", %{game_476: game1} do
      line_tile = Tile.new(62) |> Tile.switch_sides()
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile(game2, 66)
      assert game3.line_of_play === [line_tile, Tile.new(66)]
    end

    test "FAIL playing tile not in hand", %{game: game1} do
      assert {:ok, game2} = Game.play_random_tile(game1)
      [tile] = game2.line_of_play
      assert {:error, :tile_not_in_active_player} = Game.play_tile(game2, tile.id)
    end
  end

  describe "Game.play_tile_on_left_side/2" do
    test "PASS playing on left side", %{game_476: game1} do
      line_tile = Tile.new(61)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile_on_left_side(game2, 66)
      assert game3.line_of_play === [Tile.new(66), line_tile]
    end

    test "FAIL when no match", %{game: game1} do
      line_tile = Tile.new(62) |> Tile.switch_sides()
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:error, :tile_does_not_match} = Game.play_tile_on_left_side(game2, 66)
    end
  end

  describe "Game.play_tile_on_right_side/2" do
    test "PASS playing on right side", %{game_476: game1} do
      line_tile = Tile.new(62) |> Tile.switch_sides()
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, game3} = Game.play_tile_on_right_side(game2, 66)
      assert game3.line_of_play === [line_tile, Tile.new(66)]
    end

    test "FAIL when no match", %{game: game1} do
      line_tile = Tile.new(62)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:error, :tile_does_not_match} = Game.play_tile_on_right_side(game2, 66)
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
