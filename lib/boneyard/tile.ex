defmodule Boneyard.Tile do
  @enforce_keys [:left_val, :right_val]
  defstruct id: nil, left_val: nil, right_val: nil

  def new(left_val, right_val)
      when left_val >= 0 and left_val <= 9 and
             right_val >= 0 and right_val <= 9 do
    %__MODULE__{left_val: left_val, right_val: right_val}
    |> arrange()
    |> compute_id()
  end

  def new(id) when id >= 0 and id <= 9 do
    new(0, id)
  end

  def new(id) when id >= 10 and id <= 99 do
    [left_val, right_val] = Integer.digits(id)
    new(left_val, right_val)
  end

  def new({left_val, right_val}) do
    new(left_val, right_val)
  end

  def new(ids) when is_list(ids) do
    Enum.map(ids, &new/1)
  end

  defp arrange(%__MODULE__{left_val: left_val, right_val: right_val} = tile)
       when left_val < right_val,
       do: switch_sides(tile)

  defp arrange(tile), do: tile

  defp compute_id(%__MODULE__{} = tile),
    do: %{tile | id: tile.left_val * 10 + tile.right_val}

  def switch_sides(%__MODULE__{left_val: left_val, right_val: right_val} = tile),
    do: %{tile | right_val: left_val, left_val: right_val}

  def a === b do
    a = arrange(a)
    b = arrange(b)
    Kernel.===(a.left_val, b.left_val) and Kernel.===(a.right_val, b.right_val)
  end

  def compare(%__MODULE__{id: id1}, %__MODULE__{id: id2}) do
    if id1 > id2 do
      :lt
    else
      :gt
    end
  end

  def is_double(%__MODULE__{left_val: val, right_val: val}),
    do: true

  def is_double(_),
    do: false

  def scoring_sum(tiles) when is_list(tiles),
    do: tiles |> Enum.map(&scoring_sum/1) |> Enum.sum()

  def scoring_sum(%__MODULE__{left_val: left_val, right_val: right_val}),
    do: left_val + right_val

  def scoring_sum(_),
    do: 0

  def first_mover_sum(tiles) when is_list(tiles),
    do: tiles |> Enum.map(&first_mover_sum/1) |> Enum.sum()

  def first_mover_sum(%__MODULE__{left_val: left_val, right_val: right_val} = tile) do
    left_val + right_val +
      case is_double(tile) do
        true -> 1000
        false -> 0
      end
  end

  def first_mover_sum(_),
    do: 0

  def winner_sums(tiles) when is_list(tiles) do
    tiles = [new(0) | tiles]
    tiles_sum = scoring_sum(tiles)
    lowest_tile = Enum.min_by(tiles, &scoring_sum/1)

    lowest_val =
      tiles
      |> Enum.flat_map(fn x -> [x.left_val, x.right_val] end)
      |> Enum.min()

    {tiles_sum, lowest_tile, lowest_val, tiles}
  end
end

defimpl String.Chars, for: Boneyard.Tile do
  def to_string(%{left_val: left_val, right_val: right_val}),
    do: "#{left_val}/#{right_val}"
end
