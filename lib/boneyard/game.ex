defmodule Boneyard.Game do
  alias Boneyard.Tile

  defstruct num_hands: nil,
            num_tiles_per_hand: nil,
            max_tile_val: nil,
            hands: nil,
            line_of_play: nil,
            active_player: nil,
            is_round_over: nil,
            is_game_over: nil,
            last_player: nil,
            winning_player: nil,
            boneyard: nil,
            scores: nil,
            is_team: nil,
            passing_bonus: nil,
            capicú_bonus: nil,
            winning_score: nil

  def new(num_hands, num_tiles_per_hand, max_tile_val, options \\ [])

  def new(num_hands, 7 = _num_tiles_per_hand, 6 = _max_tile_val, _) when num_hands > 4 do
    {:error, :not_enough_tiles}
  end

  def new(num_hands, num_tiles_per_hand, max_tile_val, options)
      when num_hands in 2..6 and num_tiles_per_hand in [5, 7] and max_tile_val in [6, 9] do
    %__MODULE__{
      num_hands: num_hands,
      num_tiles_per_hand: num_tiles_per_hand,
      max_tile_val: max_tile_val,
      scores: List.duplicate(0, num_hands),
      is_game_over: false,
      is_team: Keyword.get(options, :is_team, false),
      passing_bonus: Keyword.get(options, :passing_bonus, 0),
      capicú_bonus: Keyword.get(options, :capicú_bonus, 0),
      winning_score: Keyword.get(options, :winning_score, 100)
    }
    |> new_round()
  end

  def new(_, _, _, _) do
    {:error, :invalid_options}
  end

  def new_round(%__MODULE__{is_game_over: true}) do
    {:error, :game_over}
  end

  def new_round(%__MODULE__{is_round_over: false}) do
    {:error, :round_not_over}
  end

  def new_round(%__MODULE__{} = game) do
    {hands, boneyard} =
      collect_tiles(game.max_tile_val)
      |> divvy_up(game.num_hands, game.num_tiles_per_hand)

    new_game = %{
      game
      | active_player: game.active_player || hand_with_highest_double_or_tile(hands),
        hands: hands,
        line_of_play: [],
        is_round_over: false,
        boneyard: boneyard,
        winning_player: nil
    }

    {:ok, new_game}
  end

  def take_from_boneyard(%__MODULE__{boneyard: []}) do
    {:error, :boneyard_empty}
  end

  def take_from_boneyard(%__MODULE__{} = game) do
    if playable_tiles(game) === [] do
      [tile | rest] = game.boneyard

      new_game = %{
        game
        | boneyard: rest,
          hands: add_tile_to_active_player(game, tile)
      }

      {:ok, tile, new_game}
    else
      {:error, :must_use_playable_tiles}
    end
  end

  def pass(%__MODULE__{is_round_over: true}) do
    {:error, :round_over}
  end

  def pass(%__MODULE__{boneyard: [_ | _]}) do
    {:error, :boneyard_not_empty}
  end

  def pass(%__MODULE__{} = game) do
    if playable_tiles(game) === [] do
      new_game =
        %{
          game
          | active_player: next_active_player(game),
            is_round_over: game.last_player === game.active_player
        }
        |> score_previous_move(nil)

      {:ok, new_game}
    else
      {:error, :must_use_playable_tiles}
    end
  end

  defp compute_game_over(%__MODULE__{} = game) do
    %{
      game
      | is_game_over: Enum.any?(game.scores, fn x -> x >= game.winning_score end)
    }
  end

  def playable_tiles(%__MODULE__{} = game) do
    left_tile = List.first(game.line_of_play)
    right_tile = List.last(game.line_of_play)

    game.hands
    |> Enum.at(game.active_player)
    |> Enum.filter(fn player_tile ->
      tiles_match?(:left_side, left_tile, player_tile) or
        tiles_match?(:right_side, right_tile, player_tile)
    end)
    |> Enum.sort()
  end

  def play_tile(%__MODULE__{} = game, tile_id) when is_binary(tile_id) do
    play_tile(game, String.to_integer(tile_id))
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

  defp do_play_tile(%__MODULE__{is_round_over: true}, _, _) do
    {:error, :round_over}
  end

  defp do_play_tile(%__MODULE__{} = game, side, tile_id) when side in [:left_side, :right_side] do
    tile = Tile.new(tile_id)

    with {:ok, tile} <- match_player_tile_to_line(side, game.line_of_play, tile),
         {:ok, new_hands} <- remove_tile_from_active_player(game, tile) do
      new_game =
        %{
          game
          | active_player: next_active_player(game),
            hands: new_hands,
            line_of_play: add_tile_to_line(side, game.line_of_play, tile),
            is_round_over: Enum.member?(new_hands, []),
            last_player: game.active_player
        }
        |> score_previous_move(tile)

      {:ok, tile, new_game}
    end
  end

  defp add_tile_to_line(:left_side, line_of_play, tile),
    do: List.insert_at(line_of_play, 0, tile)

  defp add_tile_to_line(:right_side, line_of_play, tile),
    do: List.insert_at(line_of_play, -1, tile)

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

  defp add_tile_to_active_player(
         %__MODULE__{hands: hands, active_player: active_player},
         %Tile{} = tile
       ) do
    old_hand = Enum.at(hands, active_player)
    new_hand = Enum.sort([tile | old_hand])
    List.replace_at(hands, active_player, new_hand)
  end

  defp remove_tile_from_active_player(
         %__MODULE__{hands: hands, active_player: active_player},
         %Tile{} = tile
       ) do
    old_hand = Enum.at(hands, active_player)
    {matched_tiles, new_hand} = Enum.split_with(old_hand, fn x -> Tile.===(x, tile) end)

    if matched_tiles !== [] do
      {:ok, List.replace_at(hands, active_player, new_hand)}
    else
      {:error, :tile_not_in_active_player}
    end
  end

  defp next_active_player(%__MODULE__{} = game),
    do: rem(game.active_player + 1, game.num_hands)

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
      not too_many_of_same_suit?(tiles)
  end

  defp too_many_of_same_suit?(tiles) do
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

  def capicú_bonus_points(%__MODULE__{} = game, last_tile, winning_player) do
    left_tile = List.first(game.line_of_play)
    right_tile = List.last(game.line_of_play)

    cond do
      Tile.is_double(last_tile) ->
        0

      Enum.at(game.hands, winning_player) !== [] ->
        0

      left_tile.left_val === right_tile.right_val ->
        game.capicú_bonus

      :otherwise ->
        0
    end
  end

  defp score_previous_move(%__MODULE__{is_round_over: true} = game, last_tile) do
    winning_player =
      game.hands
      |> Enum.map(&Tile.winner_sums/1)
      |> Enum.zip(0..length(game.hands))
      |> Enum.min_by(fn {total, _} -> total end)
      |> elem(1)

    players =
      if game.is_team do
        [winning_player, teammate(winning_player, game.num_hands)]
      else
        [winning_player]
      end

    bonus_points =
      game.hands
      |> Enum.map(&Tile.scoring_sum/1)
      |> Enum.sum()

    bonus_points = bonus_points + capicú_bonus_points(game, last_tile, winning_player)

    %{
      game
      | active_player: nil,
        winning_player: winning_player
    }
    |> compute_scores(bonus_points, players)
    |> compute_game_over()
  end

  defp score_previous_move(%__MODULE__{} = game, _last_tile)
       when game.active_player === game.last_player do
    potential_score = Enum.at(game.scores, game.active_player) + game.passing_bonus

    if playable_tiles(game) !== [] and potential_score < game.winning_score do
      players =
        if game.is_team do
          [game.active_player, teammate(game.active_player, game.num_hands)]
        else
          [game.active_player]
        end

      game
      |> compute_scores(game.passing_bonus, players)
      |> compute_game_over()
    else
      game
    end
  end

  defp score_previous_move(%__MODULE__{} = game, _last_tile) do
    game
  end

  defp compute_scores(%__MODULE__{} = game, bonus_points, players) do
    scores =
      game.scores
      |> Enum.zip(0..length(game.hands))
      |> Enum.map(fn {score, idx} -> compute_score(score, idx, bonus_points, players) end)

    %{game | scores: scores}
  end

  defp compute_score(score, idx, points, players) do
    if idx in players do
      score + points
    else
      score
    end
  end

  defp teammate(player, num_hands) do
    rem(player + rem(num_hands, 2), num_hands)
  end
end
