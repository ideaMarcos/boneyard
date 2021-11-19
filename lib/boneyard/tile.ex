defmodule Boneyard.Tile do
  defstruct id: nil, left_val: nil, right_val: nil

  def new(left_val, right_val)
      when left_val >= 0 and left_val <= 9 and
             right_val >= 0 and right_val <= 9 do
    %__MODULE__{left_val: left_val, right_val: right_val}
    |> arrange()
    |> calculate_id()
  end

  def new(id) when id >= 0 and id <= 9 do
    new(0, id)
  end

  def new(id) when id >= 10 and id <= 99 do
    [left_val, right_val] = Integer.digits(id)
    new(left_val, right_val)
  end

  defp arrange(%__MODULE__{left_val: left_val, right_val: right_val} = tile)
       when left_val < right_val,
       do: switch_sides(tile)

  defp arrange(tile), do: tile

  defp calculate_id(%__MODULE__{} = tile),
    do: %{tile | id: tile.left_val * 10 + tile.right_val}

  def switch_sides(%__MODULE__{left_val: left_val, right_val: right_val} = tile),
    do: %{tile | right_val: left_val, left_val: right_val}

  def left_tile === right_tile,
    do: Kernel.===(left_tile.id, right_tile.id)

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

  def scoring_sum(%__MODULE__{left_val: left_val, right_val: right_val}),
    do: left_val + right_val

  def scoring_sum(_),
    do: 0

  def first_mover_sum(%__MODULE__{left_val: left_val, right_val: right_val} = tile) do
    left_val + right_val +
      case is_double(tile) do
        true -> 1000
        false -> 0
      end
  end

  def first_mover_sum(_),
    do: 0
end

defimpl String.Chars, for: Boneyard.Tile do
  def to_string(%{left_val: val, right_val: val}),
    do: "D#{val}"

  def to_string(%{left_val: left_val, right_val: right_val}),
    do: "#{left_val}/#{right_val}"
end
