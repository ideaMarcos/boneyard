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

  def compare(%__MODULE__{} = left_tile, %__MODULE__{} = right_tile) do
    left_tile = arrange(left_tile)
    right_tile = arrange(right_tile)
    do_compare(left_tile, right_tile)
  end

  defp do_compare(%__MODULE__{} = left_tile, %__MODULE__{} = right_tile) do
    cond do
      left_tile.left_val > right_tile.left_val ->
        :lt

      left_tile.left_val < right_tile.left_val ->
        :gt

      left_tile.right_val > right_tile.right_val ->
        :lt

      :otherwise ->
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
    tiles_sum = scoring_sum(tiles)

    lowest_tile =
      tiles
      |> Enum.min_by(&scoring_sum/1, fn -> 0 end)
      |> scoring_sum()

    lowest_val =
      tiles
      |> Enum.flat_map(fn x -> [x.left_val, x.right_val] end)
      |> Enum.min(fn -> -1 end)

    {tiles_sum, lowest_tile, lowest_val}
  end
end

defimpl String.Chars, for: Boneyard.Tile do
  def to_string(%{left_val: left_val, right_val: right_val}) do
    "#{left_val}/#{right_val}"
  end
end
