defmodule Boneyard.TileTest do
  use ExUnit.Case, async: true
  alias Boneyard.Tile

  describe "new/2" do
    test "creates a tile with valid values. The larger value is on the left. The smaller value is on the right." do
      [rand_val1, rand_val2] = Enum.take_random(0..9, 2)
      low_val = min(rand_val1, rand_val2)
      high_val = max(rand_val1, rand_val2)
      tile = Tile.new(rand_val1, rand_val2)
      assert tile.left_val == high_val
      assert tile.right_val == low_val
      assert Integer.digits(tile.id) == [high_val, low_val]
    end

    test "handles double values > 0" do
      val = Enum.random(1..9)
      tile = Tile.new(val, val)
      assert tile.left_val == val
      assert tile.right_val == val
      assert Integer.digits(tile.id) == [val, val]
    end

    test "handles double 0" do
      tile = Tile.new(0, 0)
      assert tile.left_val == 0
      assert tile.right_val == 0
      assert tile.id == 0
    end
  end

  describe "new/1" do
    test "creates tile from single digit > 0" do
      val = Enum.random(1..9)
      tile = Tile.new(val)
      assert tile.left_val == val
      assert tile.right_val == 0
      assert Integer.digits(tile.id) == [val, 0]
    end

    test "creates tile from two digits, not a double" do
      val = Integer.undigits(Enum.take_random(0..9, 2))
      tile = Tile.new(val)
      assert tile.left_val in Integer.digits(val)
      assert tile.right_val in Integer.digits(val)
      assert tile.left_val > tile.right_val
    end
  end

  describe "new/1 with tuple" do
    test "creates tile from tuple" do
      tile = Tile.new({3, 6})
      assert tile.left_val == 6
      assert tile.right_val == 3
      assert tile.id == 63
    end
  end

  describe "new/1 with list" do
    test "creates multiple tiles from list of ids" do
      tiles = Tile.new([52, 63, 11])
      assert length(tiles) == 3
      assert Enum.map(tiles, & &1.id) == [52, 63, 11]
    end
  end

  describe "switch_sides/1" do
    test "switches tile values" do
      tile = Tile.new(6, 3)
      assert tile.left_val == 6
      assert tile.right_val == 3
      switched = Tile.switch_sides(tile)
      assert switched.left_val == tile.right_val
      assert switched.right_val == tile.left_val
      assert switched.id == tile.id
    end
  end

  describe "===/2" do
    test "considers tiles equal regardless of side arrangement" do
      tile1 = Tile.new(6, 3)
      tile2 = Tile.new(3, 6)
      assert Tile.===(tile1, tile2)
    end

    test "considers different tiles unequal" do
      tile1 = Tile.new(6, 3)
      tile2 = Tile.new(6, 4)
      refute Tile.===(tile1, tile2)
    end
  end

  describe "compare/2" do
    test "compares tiles by highest value first" do
      tile1 = Tile.new(6, 3)
      tile2 = Tile.new(5, 4)
      assert Tile.compare(tile1, tile2) == :lt
    end

    test "uses second value when first values are equal" do
      tile1 = Tile.new(6, 3)
      tile2 = Tile.new(6, 4)
      assert Tile.compare(tile1, tile2) == :gt
    end
  end

  describe "is_double/1" do
    test "valid doubles" do
      val = Enum.random(1..9)
      tile = Tile.new(val, val)
      assert tile.left_val == tile.right_val
      assert Tile.is_double(tile) == true
    end

    test "invalid doubles" do
      [left_val, right_val] = Enum.take_random(0..9, 2)
      tile = Tile.new(left_val, right_val)
      assert tile.left_val != tile.right_val
      assert Tile.is_double(tile) == false
    end
  end
end
