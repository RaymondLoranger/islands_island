defmodule Islands.IslandTest do
  use ExUnit.Case, async: true

  alias Islands.{Coord, Island}

  doctest Island

  setup_all do
    {:ok, square_coord} = Coord.new(1, 1)
    {:ok, dot_coord} = Coord.new(1, 2)
    {:ok, l_shape_coord} = Coord.new(6, 6)

    {:ok, square} = Island.new(:square, square_coord)
    {:ok, dot} = Island.new(:dot, dot_coord)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_coord)

    coords = %{
      square: square_coord,
      dot: dot_coord,
      l_shape: l_shape_coord
    }

    islands = %{
      square: square,
      dot: dot,
      l_shape: l_shape
    }

    {:ok, coords: coords, islands: islands}
  end

  describe "An island struct" do
    test "can be encoded by Poison", %{islands: islands} do
      assert Poison.encode!(islands.dot) ==
               ~s<{\"type\":\"dot\",\"hits\":[],\"coords\":[{\"row\":1,\"col\":2}]}>
    end

    test "can be encoded by Jason", %{islands: islands} do
      assert Jason.encode!(islands.dot) ==
               ~s<{\"coords\":[{\"col\":2,\"row\":1}],\"hits\":[],\"type\":\"dot\"}>
    end
  end

  describe "Island.new/2" do
    test "returns {:ok, ...} given valid args" do
      {:ok, coord} = Coord.new(4, 6)

      assert {:ok, %Island{type: :l_shape, coords: _coords, hits: _hits}} =
               Island.new(:l_shape, coord)
    end

    test "returns {:error, ...} given invalid island type" do
      {:ok, coord} = Coord.new(9, 3)
      assert Island.new(:wrong, coord) == {:error, :invalid_island_args}
    end

    test "returns {:error, ...} given invalid origin location" do
      {:ok, coord} = Coord.new(10, 10)
      assert Island.new(:l_shape, coord) == {:error, :invalid_island_location}
    end

    test "returns {:error, ...} given invalid origin type" do
      coord = %{row: 3, col: 7}
      assert Island.new(:l_shape, coord) == {:error, :invalid_island_args}
    end
  end

  describe "Island.overlaps?/2" do
    test "asserts islands overlapping", %{islands: islands} do
      assert Island.overlaps?(islands.square, islands.dot)
    end

    test "refutes islands overlapping", %{islands: islands} do
      refute Island.overlaps?(islands.square, islands.l_shape)
    end
  end

  describe "Island.guess/2" do
    test "detects a hit guess", %{islands: islands, coords: coords} do
      assert {:hit, %Island{type: :dot}} = Island.guess(islands.dot, coords.dot)
    end

    test "detect a miss guess", %{islands: islands} do
      {:ok, coord} = Coord.new(3, 4)
      assert Island.guess(islands.dot, coord) == :miss
    end
  end

  describe "Island.forested?/1" do
    test "asserts island forested", %{islands: islands, coords: coords} do
      {:hit, dot} = Island.guess(islands.dot, coords.dot)
      assert Island.forested?(dot)
    end

    test "refutes island forested", %{islands: islands} do
      {:ok, coord} = Coord.new(3, 4)
      assert Island.guess(islands.dot, coord) == :miss
      refute Island.forested?(islands.dot)
    end
  end
end