defmodule Boneyard.Cpu do
  alias Boneyard.Game
  alias Boneyard.Tile

  def play_random_tile(%Game{is_round_over: true}) do
    {:error, :round_over}
  end

  def play_random_tile(%Game{} = game) do
    game
    |> Game.playable_tiles()
    |> case do
      [] ->
        {:error, :no_playable_tiles}

      tiles ->
        Enum.random(tiles)
        |> then(&Game.play_tile(game, &1.id))
    end
  end

  def play_best_tile(%Game{is_round_over: true}) do
    {:error, :round_over}
  end

  def play_best_tile(%Game{} = game) do
    game
    |> Game.playable_tiles()
    |> Enum.sort_by(&Tile.first_mover_sum/1)
    |> List.last()
    |> case do
      nil -> {:error, :no_playable_tiles}
      tile -> Game.play_tile(game, tile.id)
    end
  end

  # Playing until no playable tiles (before passing)
  def play_until_no_playable_tiles(%Game{} = game) do
    play_best_tile(game)
    |> do_play_until_no_playable_tiles(game)
  end

  defp do_play_until_no_playable_tiles({:ok, _, game}, _) do
    play_until_no_playable_tiles(game)
  end

  defp do_play_until_no_playable_tiles({:error, error}, game) do
    {:error, error, game}
  end

  # Playing or passing until round is over
  def play_until_round_over(%Game{} = game) do
    play_best_tile(game)
    |> do_play_until_round_over(game)
  end

  defp do_play_until_round_over({:ok, game}, _) do
    play_until_round_over(game)
  end

  defp do_play_until_round_over({:ok, _, game}, _) do
    play_until_round_over(game)
  end

  defp do_play_until_round_over({:error, :round_over}, game) do
    {:error, :round_over, game}
  end

  defp do_play_until_round_over({:error, :no_playable_tiles}, game) do
    Game.take_from_boneyard(game)
    |> do_play_until_round_over(game)
  end

  defp do_play_until_round_over({:error, :boneyard_empty}, game) do
    Game.pass(game)
    |> do_play_until_round_over(game)
  end
end
