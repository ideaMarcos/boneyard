defmodule Boneyard.Game do
  alias Boneyard.Tile

  defstruct num_hands: nil,
            num_tiles_per_hand: nil,
            max_tile_val: nil,
            hands: nil,
            line_of_play: nil,
            active_hand: nil,
            is_round_over: nil,
            is_game_over: nil,
            pass_count: nil,
            boneyard: nil,
            scores: nil

  def new(num_hands, num_tiles_per_hand, max_tile_val)
      when num_hands in [2, 3, 4] and num_tiles_per_hand in [5, 7] and max_tile_val in [6, 9] do
    {hands, boneyard} =
      collect_tiles(max_tile_val)
      |> divvy_up(num_hands, num_tiles_per_hand)

    game = %__MODULE__{
      active_hand: hand_with_highest_double_or_tile(hands),
      hands: hands,
      num_hands: num_hands,
      num_tiles_per_hand: num_tiles_per_hand,
      max_tile_val: max_tile_val,
      line_of_play: [],
      is_round_over: false,
      is_game_over: false,
      pass_count: 0,
      boneyard: boneyard,
      scores: Enum.map(hands, fn _ -> 0 end)
    }

    {:ok, game}
  end

  def new(_, _, _) do
    {:error, :invalid_options}
  end

  # def score_round(%__MODULE__{is_round_over: true} = game) do
  #   game = %__MODULE__{
  #     scores: Enum.map(game.scores, fn x -> x + 20 end)
  #   }

  #   {:ok, game}
  # end

  # def new_round(%__MODULE__{boneyard: []} = game) do
  #   {hands, boneyard} =
  #     collect_tiles(game.max_tile_val)
  #     |> divvy_up(game.num_hands, game.num_tiles_per_hand)

  #   game = %__MODULE__{
  #     active_hand: hand_with_highest_double_or_tile(hands),
  #     hands: hands,
  #     line_of_play: [],
  #     is_round_over: false,
  #     is_game_over: false,
  #     pass_count: 0,
  #     boneyard: boneyard
  #   }

  #   {:ok, game}
  # end

  def take_from_boneyard(%__MODULE__{boneyard: []} = game) do
    pass(game)
  end

  def take_from_boneyard(%__MODULE__{} = game) do
    [tile, rest] = game.boneyard

    new_game = %{
      game
      | boneyard: rest,
        hands: add_tile_to_active_hand(game, tile)
    }

    {:ok, new_game}
  end

  def pass(%__MODULE__{is_round_over: true} = game) do
    {:error, :game_over, game}
  end

  def pass(%__MODULE__{} = game) do
    case playable_tiles(game) do
      [] ->
        new_game = %{
          game
          | active_hand: next_active_hand(game),
            is_round_over: game.pass_count + 1 >= game.num_hands,
            pass_count: game.pass_count + 1
        }

        {:ok, new_game}

      _ ->
        {:error, :must_use_playable_tiles, game}
    end
  end

  def play_random_tile(%__MODULE__{} = game) do
    tile =
      game
      |> playable_tiles()
      |> Enum.sort_by(&Tile.first_mover_sum/1)
      |> List.last()

    if not is_nil(tile) do
      play_tile(game, tile.id)
    else
      {:error, :no_playable_tiles, game}
    end
  end

  def playable_tiles(%__MODULE__{} = game) do
    left_tile = List.first(game.line_of_play)
    right_tile = List.last(game.line_of_play)

    game.hands
    |> Enum.at(game.active_hand)
    |> Enum.filter(fn player_tile ->
      tiles_match?(:left_side, left_tile, player_tile) or
        tiles_match?(:right_side, right_tile, player_tile)
    end)
    |> Enum.sort()
  end

  def play_tile(%__MODULE__{} = game, tile_id) when is_integer(tile_id) do
    case play_tile_on_left_side(game, tile_id) do
      {:error, _} ->
        play_tile_on_right_side(game, tile_id)

      ok ->
        ok
    end
  end

  def play_tile_on_right_side(%__MODULE__{} = game, tile_id) when is_integer(tile_id) do
    do_play_tile(%__MODULE__{} = game, :right_side, tile_id)
  end

  def play_tile_on_left_side(%__MODULE__{} = game, tile_id) when is_integer(tile_id) do
    do_play_tile(%__MODULE__{} = game, :left_side, tile_id)
  end

  defp do_play_tile(%__MODULE__{is_round_over: true} = game, _, _) do
    {:error, :game_over, game}
  end

  defp do_play_tile(%__MODULE__{} = game, side, tile_id) when side in [:left_side, :right_side] do
    player_tile = Tile.new(tile_id)

    with {:ok, player_tile} <- match_player_tile_to_line(side, game.line_of_play, player_tile),
         {:ok, new_hands} <- remove_tile_from_active_hand(game, player_tile) do
      new_game = %{
        game
        | active_hand: next_active_hand(game),
          hands: new_hands,
          line_of_play: add_tile_to_line(side, game.line_of_play, player_tile),
          is_round_over: Enum.any?(new_hands, fn hand -> hand === [] end),
          pass_count: 0
      }

      {:ok, new_game}
    end
  end

  defp add_tile_to_line(:left_side, line_of_play, player_tile),
    do: List.insert_at(line_of_play, 0, player_tile)

  defp add_tile_to_line(:right_side, line_of_play, player_tile),
    do: List.insert_at(line_of_play, -1, player_tile)

  defp match_player_tile_to_line(:left_side = side, line_of_play, player_tile) do
    line_tile = List.first(line_of_play)
    match_tiles(side, line_tile, player_tile)
  end

  defp match_player_tile_to_line(:right_side = side, line_of_play, player_tile) do
    line_tile = List.last(line_of_play)
    match_tiles(side, line_tile, player_tile)
  end

  defp match_tiles(_, nil = _line_empty, %Tile{} = player_tile),
    do: {:ok, player_tile}

  defp match_tiles(:left_side, %Tile{left_val: val}, %Tile{left_val: val} = player_tile),
    do: {:ok, Tile.switch_sides(player_tile)}

  defp match_tiles(:left_side, %Tile{left_val: val}, %Tile{right_val: val} = player_tile),
    do: {:ok, player_tile}

  defp match_tiles(:right_side, %Tile{right_val: val}, %Tile{right_val: val} = player_tile),
    do: {:ok, Tile.switch_sides(player_tile)}

  defp match_tiles(:right_side, %Tile{right_val: val}, %Tile{left_val: val} = player_tile),
    do: {:ok, player_tile}

  defp match_tiles(_, _, _),
    do: {:error, :tile_does_not_match}

  defp tiles_match?(side, line_tile, %Tile{} = player_tile) do
    case match_tiles(side, line_tile, player_tile) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp add_tile_to_active_hand(
         %__MODULE__{hands: hands, active_hand: active_hand},
         %Tile{} = tile
       ) do
    old_hand = Enum.at(hands, active_hand)
    new_hand = Enum.sort(old_hand ++ tile)

    List.replace_at(hands, active_hand, new_hand)
  end

  defp remove_tile_from_active_hand(
         %__MODULE__{hands: hands, active_hand: active_hand},
         %Tile{} = player_tile
       ) do
    old_hand = Enum.at(hands, active_hand)
    new_hand = Enum.reject(old_hand, fn x -> Tile.===(x, player_tile) end)

    if length(old_hand) == length(new_hand) + 1 do
      {:ok, List.replace_at(hands, active_hand, new_hand)}
    else
      {:error, :tile_not_in_active_hand}
    end
  end

  defp next_active_hand(game),
    do: rem(game.active_hand + 1, game.num_hands)

  defp collect_tiles(max_tile_val) do
    for left_val <- 0..max_tile_val, right_val <- 0..left_val do
      Tile.new(left_val, right_val)
    end
  end

  def divvy_up(tiles, num_hands, num_tiles_per_hand)
      when is_list(tiles),
      do: do_divvy_up(tiles, num_hands, num_tiles_per_hand, 10)

  defp do_divvy_up(tiles, num_hands, num_tiles_per_hand, attempt) do
    potential_hands =
      tiles
      |> Enum.shuffle()
      |> Enum.chunk_every(num_tiles_per_hand)
      |> Enum.map(&Enum.sort/1)

    hands = Enum.slice(potential_hands, 0, num_hands)

    if attempt <= 1 or Enum.all?(hands, &hand_fair?/1) do
      boneyard =
        potential_hands
        |> Enum.slice(num_hands, length(potential_hands))
        |> List.flatten()
        |> Enum.sort()

      {hands, boneyard}
    else
      tiles
      |> do_divvy_up(num_hands, num_tiles_per_hand, attempt - 1)
    end
  end

  defp hand_fair?(tiles) do
    not too_many_doubles?(tiles) and
      not too_many_of_same_value?(tiles)
  end

  defp too_many_of_same_value?(tiles) do
    tiles
    |> Enum.flat_map(fn x -> Enum.uniq([x.left_val, x.right_val]) end)
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.any?(fn x -> x > 4 end)
  end

  defp too_many_doubles?(tiles) do
    tiles
    |> Enum.count(fn t -> Tile.is_double(t) end)
    |> Kernel.>(3)
  end

  defp hand_with_highest_double_or_tile(hands) do
    max_tile_of_hand = fn hand -> Enum.max_by(hand, fn tile -> Tile.first_mover_sum(tile) end) end

    hands
    |> Enum.map(fn hand -> max_tile_of_hand.(hand) end)
    |> Enum.zip(0..length(hands))
    |> Enum.max_by(fn {tile, _} -> Tile.first_mover_sum(tile) end)
    |> elem(1)
  end
end
