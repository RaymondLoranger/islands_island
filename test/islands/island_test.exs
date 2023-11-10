defmodule Islands.IslandTest do
  use ExUnit.Case, async: true

  alias Islands.{Coord, Island}

  doctest Island

  setup_all do
    {:ok, square_origin} = Coord.new(1, 1)
    {:ok, dot_origin} = Coord.new(1, 2)
    {:ok, l_shape_origin} = Coord.new(6, 6)

    {:ok, square} = Island.new(:square, square_origin)
    {:ok, dot} = Island.new(:dot, dot_origin)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_origin)

    origins = %{
      square: square_origin,
      dot: dot_origin,
      l_shape: l_shape_origin
    }

    islands = %{
      square: square,
      dot: dot,
      l_shape: l_shape
    }

    poison =
      ~s<{"hits":[],"coords":[{"col":2,"row":1}],"origin":{"col":2,"row":1},"type":"dot"}>

    jason =
      ~s<{"type":"dot","origin":{"row":1,"col":2},"coords":[{"row":1,"col":2}],"hits":[]}>

    decoded = %{
      "coords" => [%{"col" => 2, "row" => 1}],
      "hits" => [],
      "type" => "dot",
      "origin" => %{"col" => 2, "row" => 1}
    }

    %{
      json: %{poison: poison, jason: jason, decoded: decoded},
      islands: islands,
      origins: origins
    }
  end

  describe "An island struct" do
    test "can be encoded by Poison", %{islands: islands, json: json} do
      assert Poison.encode!(islands.dot) == json.poison
      assert Poison.decode!(json.poison) == json.decoded
    end

    test "can be encoded by Jason", %{islands: islands, json: json} do
      assert Jason.encode!(islands.dot) == json.jason
      assert Jason.decode!(json.jason) == json.decoded
    end
  end

  describe "Island.new/2" do
    test "returns {:ok, island} given valid args" do
      {:ok, origin} = Coord.new(4, 6)
      {:ok, island} = Island.new(:l_shape, origin)
      %Island{type: type, origin: ^origin, coords: coords, hits: hits} = island
      assert type == :l_shape
      assert hits == MapSet.new()

      assert coords ==
               MapSet.new([
                 Coord.new!(4, 6),
                 Coord.new!(5, 6),
                 Coord.new!(6, 6),
                 Coord.new!(6, 7)
               ])
    end

    test "returns {:error, reason} given invalid island type" do
      {:ok, origin} = Coord.new(9, 3)
      assert Island.new(:wrong, origin) == {:error, :invalid_island_args}
    end

    test "returns {:error, reason} given invalid origin location" do
      {:ok, origin} = Coord.new(10, 10)
      assert Island.new(:l_shape, origin) == {:error, :invalid_island_location}
    end

    test "returns {:error, reason} given invalid origin type" do
      origin = %{row: 3, col: 7}
      assert Island.new(:l_shape, origin) == {:error, :invalid_island_args}
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
    test "detects a hit guess", %{islands: islands, origins: origins} do
      assert {:hit, %Island{type: :dot}} =
               Island.guess(islands.dot, origins.dot)
    end

    test "detects a miss guess", %{islands: islands} do
      {:ok, origin} = Coord.new(3, 4)
      assert Island.guess(islands.dot, origin) == :miss
    end
  end

  describe "Island.forested?/1" do
    test "asserts island forested", %{islands: islands, origins: origins} do
      {:hit, dot} = Island.guess(islands.dot, origins.dot)
      assert Island.forested?(dot)
    end

    test "refutes island forested", %{islands: islands} do
      {:ok, origin} = Coord.new(3, 4)
      assert Island.guess(islands.dot, origin) == :miss
      refute Island.forested?(islands.dot)
    end
  end
end
