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
    {:ok, game_379} = Game.new(3, 7, 9)
    %{game: game, game_476: game_476, game_379: game_379}
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
      assert {:error, :no_playable_tiles, game2} = play_until_no_playable_tiles(game1)
      assert Game.playable_tiles(game2) === []
      assert is_nil(game2.last_player) === false
      assert game2.boneyard === []
      assert {:ok, game3} = Game.pass(game2)
      assert game3.active_player === 0 or game3.active_player > game2.active_player
      assert game3.last_player === game2.last_player
    end

    test "FAIL when playable tile available", %{game_476: game1} do
      assert Game.playable_tiles(game1) !== []
      assert {:error, :must_use_playable_tiles} = Game.pass(game1)
    end

    test "FAIL when boneyard not empty", %{game_379: game1} do
      assert {:error, :no_playable_tiles, game2} = play_until_no_playable_tiles(game1)
      assert game2.boneyard !== []
      assert {:error, :boneyard_not_empty} = Game.pass(game2)
    end

    test "FAIL when round over", %{game_379: game1} do
      assert game1.is_round_over === false
      assert {:error, :round_over, game2} = play_until_round_over(game1)
      assert game2.is_round_over === true
      assert {:error, :round_over} = Game.pass(game2)
    end
  end

  describe "Game.take_from_boneyard/1" do
    test "PASS when boneyard not empty", %{game_379: game1} do
      assert {:error, :no_playable_tiles, game2} = play_until_no_playable_tiles(game1)
      assert game2.boneyard !== []
      assert {:ok, tile, game3} = Game.take_from_boneyard(game2)
      assert tile_in_any_hand(game2.hands, tile) === false
      assert tile_in_hand(game2.boneyard, tile) === true

      assert game3.active_player === game2.active_player
      hand = Enum.at(game3.hands, game3.active_player)
      assert tile_in_hand(hand, tile) === true
    end

    test "FAIL when boneyard empty", %{game_476: game1} do
      assert game1.boneyard === []
      assert {:error, :boneyard_empty} = Game.take_from_boneyard(game1)
    end

    test "FAIL when playable tile available", %{game_379: game1} do
      assert Game.playable_tiles(game1) !== []
      assert {:error, :must_use_playable_tiles} = Game.take_from_boneyard(game1)
    end
  end

  describe "Game.play_random_tile/1" do
    test "PASS playing tile in hand", %{game: game1} do
      assert {:ok, tile, game2} = Game.play_random_tile(game1)
      assert game2.last_player === game1.active_player
      assert [^tile] = game2.line_of_play
      assert tile_in_any_hand(game2.hands, tile) === false

      hand = Enum.at(game1.hands, game1.active_player)
      assert tile_in_hand(hand, tile) === true
    end

    test "FAIL when round over", %{game_379: game1} do
      assert game1.is_round_over === false
      assert {:error, :round_over, game2} = play_until_round_over(game1)
      assert game2.is_round_over === true
      assert {:error, :round_over} = Game.play_random_tile(game2)
    end
  end

  describe "Game.play_tile/2" do
    test "PASS playing tile in hand", %{game: game1} do
      player_tile =
        game1
        |> Game.playable_tiles()
        |> Enum.random()

      hand = Enum.at(game1.hands, game1.active_player)
      assert tile_in_hand(hand, player_tile) === true
      assert {:ok, player_tile, game2} = Game.play_tile(game1, player_tile.id)
      assert game2.active_player === 0 or game2.active_player > game1.active_player
      assert game2.last_player === game1.active_player
      assert game2.line_of_play === [player_tile]
      assert tile_in_any_hand(game2.hands, player_tile) === false
    end

    test "PASS playing on left side", %{game_476: game1} do
      line_tile = Tile.new(61)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, player_tile, game3} = Game.play_tile(game2, 66)
      assert game3.line_of_play === [player_tile, line_tile]
    end

    test "PASS playing on right side", %{game_476: game1} do
      line_tile = Tile.new(62) |> Tile.switch_sides()
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, player_tile, game3} = Game.play_tile(game2, 66)
      assert player_tile === Tile.new(66)
      assert game3.line_of_play === [line_tile, player_tile]
    end

    test "FAIL playing tile not in hand", %{game: game1} do
      assert {:ok, tile, game2} = Game.play_random_tile(game1)
      assert [^tile] = game2.line_of_play
      assert {:error, :tile_not_in_active_player} = Game.play_tile(game2, tile.id)
    end

    test "FAIL when round over", %{game_379: game1} do
      assert game1.is_round_over === false
      assert {:error, :round_over, game2} = play_until_round_over(game1)
      assert game2.is_round_over === true
      tile_id = Enum.random(0..game1.max_tile_val)
      assert {:error, :round_over} = Game.play_tile(game2, tile_id)
    end
  end

  describe "Game.play_tile_on_left_side/2" do
    test "PASS playing on left side", %{game_476: game1} do
      line_tile = Tile.new(61)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:ok, player_tile, game3} = Game.play_tile_on_left_side(game2, 66)
      assert player_tile === Tile.new(66)
      assert game3.line_of_play === [player_tile, line_tile]
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

      assert {:ok, player_tile, game3} = Game.play_tile_on_right_side(game2, 66)
      assert player_tile === Tile.new(66)
      assert game3.line_of_play === [line_tile, player_tile]
    end

    test "FAIL when no match", %{game: game1} do
      line_tile = Tile.new(62)
      game2 = %{game1 | line_of_play: [line_tile]}

      assert {:error, :tile_does_not_match} = Game.play_tile_on_right_side(game2, 66)
    end
  end

  describe "Game.is_round_over" do
    test "PASS when game is locked. NO passing_bonus", %{game_476: game1} do
      assert {:ok, _, game2} = Game.play_random_tile(game1)

      game3 = %{
        game2
        | line_of_play: [Tile.new(99)],
          hands: Enum.map(1..4, fn x -> [Tile.new(x)] end)
      }

      assert {:ok, game4} = Game.pass(game3)
      assert {:ok, game5} = Game.pass(game4)
      assert {:ok, game6} = Game.pass(game5)
      assert {:ok, game7} = Game.pass(game6)

      assert game2.is_round_over === false
      assert game3.is_round_over === false
      assert game4.is_round_over === false
      assert game5.is_round_over === false
      assert game6.is_round_over === false
      assert Enum.all?(game6.scores, fn x -> x === 0 end)
      assert game7.is_round_over === true
      assert Enum.sum(game7.scores) === 10
      assert Enum.at(game7.scores, game7.winning_player) === 10
    end

    test "PASS when any player has empty hand", %{game: game1} do
      assert {:ok, line_tile, game2} = Game.play_random_tile(game1)

      game3 = %{
        game2
        | hands: Enum.map(1..game2.num_hands, fn _ -> [line_tile] end)
      }

      assert {:ok, _, game4} = Game.play_random_tile(game3)
      assert game4.is_round_over === true
      assert Enum.member?(game4.hands, []) === true
    end

    test "FAIL when player locks out others. GET passing_bonus if it bonus + player score < winning score",
         %{game_476: game1} do
      assert {:ok, _, game2} = Game.play_random_tile(game1)

      game3 = %{
        game2
        | line_of_play: [Tile.new(11)],
          hands: Enum.map(1..4, fn x -> [Tile.new(x, x), Tile.new(x, 9)] end),
          active_player: 0,
          last_player: 5,
          winning_score: game2.passing_bonus + 1
      }

      assert {:ok, _, game4} = Game.play_random_tile(game3)
      assert {:ok, game5} = Game.pass(game4)
      assert {:ok, game6} = Game.pass(game5)
      assert {:ok, game7} = Game.pass(game6)
      assert Game.playable_tiles(game7) !== []

      assert game2.is_round_over === false
      assert game3.is_round_over === false
      assert game4.is_round_over === false
      assert game5.is_round_over === false
      assert game6.is_round_over === false
      assert Enum.all?(game6.scores, fn x -> x === 0 end)
      assert game7.is_round_over === false
      assert Enum.sum(game7.scores) === game7.passing_bonus
      assert Enum.at(game7.scores, game7.last_player) === game7.passing_bonus
    end

    test "FAIL when player locks out others. NO passing_bonus if it bonus + player score >= winning score",
         %{game_476: game1} do
      assert {:ok, _, game2} = Game.play_random_tile(game1)

      game3 = %{
        game2
        | line_of_play: [Tile.new(11)],
          hands: Enum.map(1..4, fn x -> [Tile.new(x, x), Tile.new(x, 9)] end),
          active_player: 0,
          last_player: 5,
          winning_score: game2.passing_bonus
      }

      assert {:ok, _, game4} = Game.play_random_tile(game3)
      assert {:ok, game5} = Game.pass(game4)
      assert {:ok, game6} = Game.pass(game5)
      assert {:ok, game7} = Game.pass(game6)

      assert game7.is_round_over === false
      assert game6.scores === game7.scores
    end
  end

  # Playing until no playable tiles (before passing)
  defp play_until_no_playable_tiles(game) do
    Game.play_random_tile(game)
    |> play_until_no_playable_tiles(game)
  end

  defp play_until_no_playable_tiles({:ok, _, game}, _) do
    play_until_no_playable_tiles(game)
  end

  defp play_until_no_playable_tiles({:error, error}, game) do
    {:error, error, game}
  end

  # Playing or passing until round is over
  defp play_until_round_over(game) do
    Game.play_random_tile(game)
    |> play_until_round_over(game)
  end

  defp play_until_round_over({:ok, game}, _) do
    play_until_round_over(game)
  end

  defp play_until_round_over({:ok, _, game}, _) do
    play_until_round_over(game)
  end

  defp play_until_round_over({:error, :round_over}, game) do
    {:error, :round_over, game}
  end

  defp play_until_round_over({:error, :no_playable_tiles}, game) do
    Game.take_from_boneyard(game)
    |> play_until_round_over(game)
  end

  defp play_until_round_over({:error, :boneyard_empty}, game) do
    Game.pass(game)
    |> play_until_round_over(game)
  end

  defp tile_in_any_hand(hands, tile) do
    Enum.any?(hands, &tile_in_hand(&1, tile))
  end

  defp tile_in_hand(hand, tile) do
    Enum.any?(hand, &Tile.===(&1, tile))
  end
end
