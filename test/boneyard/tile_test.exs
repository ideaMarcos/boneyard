defmodule Boneyard.TileTest do
  use ExUnit.Case, async: true
  alias Boneyard.Tile

  describe "Tile" do
    test "new/1" do
      actual = Tile.new(13)
      expected = %Boneyard.Tile{left_val: 3, right_val: 1, id: 31}
      assert actual == expected
    end

    test "new/2" do
      actual = Tile.new(2, 5)
      expected = %Boneyard.Tile{id: 52, left_val: 5, right_val: 2}
      assert actual == expected
    end

    test "new/1 == new/2" do
      left_val = Enum.random(1..9)
      right_val = Enum.random(1..9)
      new2 = Tile.new(left_val, right_val)
      new1 = Tile.new(new2.id)
      assert new1 === new2
    end

    test "is_double == true" do
      val = Enum.random(1..5)
      tile = Tile.new(val, val)
      assert Tile.is_double(tile) === true
    end

    test "is_double == false" do
      val = Enum.random(1..5)
      tile = Tile.new(val - 1, val)
      assert Tile.is_double(tile) === false
    end

    test "compare/2" do
      val = Enum.random(1..5)

      tiles = [
        Tile.new(val, val),
        Tile.new(val + 1, val + 1),
        Tile.new(val - 1, val - 1),
        Tile.new(val + 1, val),
        Tile.new(val - 1, val)
      ]

      actual = Enum.sort(tiles)

      expected = [
        Tile.new(val - 1, val - 1),
        Tile.new(val - 1, val),
        Tile.new(val, val),
        Tile.new(val + 1, val),
        Tile.new(val + 1, val + 1)
      ]

      assert actual == expected
    end
  end
end
