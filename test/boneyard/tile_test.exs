defmodule Boneyard.TileTest do
  use ExUnit.Case, async: true
  alias Boneyard.Tile

  doctest Tile

  describe "Tile.new/1" do
    test "PASS" do
      actual = Tile.new(1)
      expected = %Boneyard.Tile{left_val: 1, right_val: 0, id: 10}
      assert actual == expected
    end
  end

  describe "Tile.new/2" do
    test "PASS" do
      actual = Tile.new(2, 5)
      expected = %Boneyard.Tile{id: 52, left_val: 5, right_val: 2}
      assert actual == expected
    end
  end

  describe "Tile.new/1 == Tile.new/2" do
    test "PASS" do
      left_val = Enum.random(0..9)
      right_val = Enum.random(0..9)
      new2 = Tile.new(left_val, right_val)
      new1 = Tile.new(new2.id)
      assert new1 === new2
    end
  end

  describe "Tile.is_double/1" do
    test "PASS when double" do
      val = Enum.random(1..5)
      tile = Tile.new(val, val)
      assert Tile.is_double(tile) === true
    end

    test "PASS when not double" do
      val = Enum.random(1..5)
      tile = Tile.new(val - 1, val)
      assert Tile.is_double(tile) === false
    end
  end

  describe "Tile.compare/2" do
    test "PASS using sort" do
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

  describe "Tile.first_mover_sum/1" do
    test "PASS" do
      val = Enum.random(1..6)
      assert Tile.new(val) |> Tile.first_mover_sum() === val
      assert Tile.new([val]) |> Tile.first_mover_sum() === val
      assert Tile.new(val, val) |> Tile.first_mover_sum() === 1000 + 2 * val
      assert Tile.new([{val, val}]) |> Tile.first_mover_sum() === 1000 + 2 * val

      assert Tile.new([{val, val - 1}, {val, val}]) |> Tile.first_mover_sum() ===
               1000 + 4 * val - 1
    end
  end

  describe "Tile.winner_sums/1" do
    test "PASS" do
      val = Enum.random(1..6)

      assert Tile.new([{val, val - 1}, {val, val}]) |> Tile.winner_sums() ===
               {4 * val - 1, 2 * val - 1, val - 1}

      assert Tile.new([]) |> Tile.winner_sums() === {0, 0, -1}
    end
  end

  describe "to_string/1 of Tile" do
    test "PASS" do
      val = Enum.random(1..6)
      tile = Tile.new({val, val - 1})
      assert to_string(tile) === "#{tile.left_val}/#{tile.right_val}"
      assert to_string(Tile.switch_sides(tile)) === "#{tile.right_val}/#{tile.left_val}"
    end
  end
end
