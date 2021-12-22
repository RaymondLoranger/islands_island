# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Island do
  @island "[`island`](`t:Islands.Island.t/0`)"
  @readme "https://github.com/RaymondLoranger/islands_vue_client#readme"

  @moduledoc """
  An #{@island} struct and functions for the [Game of Islands](#{@readme}).

  The #{@island} struct contains the fields type, origin, coords and hits
  representing the characteristics of an island in the _Game of Islands_.

  ##### Based on the book [Functional Web Development](https://pragprog.com/book/lhelph/functional-web-development-with-elixir-otp-and-phoenix) by Lance Halvorsen.
  """

  alias __MODULE__
  alias __MODULE__.Offsets
  alias Islands.Coord

  @types [:atoll, :dot, :l_shape, :s_shape, :square]

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:type, :origin, :coords, :hits]
  defstruct [:type, :origin, :coords, :hits]

  @typedoc "A set of squares"
  @type coords :: MapSet.t(Coord.t())
  @typedoc ~s|Grid cell e.g. "a1" or "c3"|
  # Size of bitstring is 16 bits => 2 bytes!
  @type grid_cell :: <<_::16>>
  @typedoc "A map representing a CSS grid position"
  @type grid_position :: %{
          gridColumnStart: Coord.col(),
          gridRowStart: Coord.row()
        }
  @typedoc "An island struct for the Game of Islands"
  @type t :: %Island{
          type: type,
          origin: Coord.t(),
          coords: coords,
          hits: coords
        }
  @typedoc "Island types"
  @type type :: :atoll | :dot | :l_shape | :s_shape | :square

  @doc """
  Returns `{:ok, island}` or `{:error, reason}` if given an invalid `type` or
  `origin`.

  ## Examples

      iex> alias Islands.{Coord, Island}
      iex> {:ok, origin} = Coord.new(1, 1)
      iex> {:ok, island} = Island.new(:dot, origin)
      iex> %Island{origin: ^origin, coords: coords, hits: hits} = island
      iex> {coords, hits}
      {MapSet.new([origin]), MapSet.new()}
  """
  @spec new(type, Coord.t()) :: {:ok, t} | {:error, atom}
  def new(type, %Coord{} = origin) when type in @types do
    with [_ | _] = coords <- Offsets.new(type) |> coords(origin) do
      {coords, hits} = {MapSet.new(coords), MapSet.new()}
      {:ok, %Island{type: type, origin: origin, coords: coords, hits: hits}}
    else
      :error -> {:error, :invalid_island_location}
    end
  end

  def new(_type, _origin), do: {:error, :invalid_island_args}

  @doc """
  Returns an #{@island} struct or raises if given an invalid `type` or `origin`.

  ## Examples

      iex> alias Islands.{Coord, Island}
      iex> origin = Coord.new!(1, 1)
      iex> %Island{coords: coords, hits: hits} = Island.new!(:dot, origin)
      iex> {coords, hits}
      {MapSet.new([origin]), MapSet.new()}

      iex> alias Islands.{Coord, Island}
      iex> origin = Coord.new!(10, 9)
      iex> Island.new!(:square, origin)
      ** (ArgumentError) cannot create island, reason: :invalid_island_location

      iex> alias Islands.Island
      iex> origin = %{row: 10, col: 9}
      iex> Island.new!(:square, origin)
      ** (ArgumentError) cannot create island, reason: :invalid_island_args
  """
  @spec new!(type, Coord.t()) :: t
  def new!(type, origin) do
    case new(type, origin) do
      {:ok, island} ->
        island

      {:error, reason} ->
        raise ArgumentError, "cannot create island, reason: #{inspect(reason)}"
    end
  end

  @doc """
  Checks if `new_island` overlaps `island`.

  ## Examples

      iex> alias Islands.{Coord, Island}
      iex> square_origin = Coord.new!(1, 1)
      iex> atoll_origin = Coord.new!(2, 2)
      iex> square = Island.new!(:square, square_origin)
      iex> atoll = Island.new!(:atoll, atoll_origin)
      iex> Island.overlaps?(atoll, square)
      true
  """
  @spec overlaps?(t, t) :: boolean
  def overlaps?(%Island{} = new_island, %Island{} = island) do
    not MapSet.disjoint?(new_island.coords, island.coords)
  end

  @doc """
  Returns `{:hit, updated_island}`, where updated_island is `island`
  consequently updated if `guess` was a hit, or `:miss` otherwise.
  """
  @spec guess(t, Coord.t()) :: {:hit, t} | :miss
  def guess(%Island{} = island, %Coord{} = guess) do
    if MapSet.member?(island.coords, guess),
      do: {:hit, update_in(island.hits, &MapSet.put(&1, guess))},
      else: :miss
  end

  @doc """
  Checks if all the squares of `island` have been hit.
  """
  @spec forested?(t) :: boolean
  def forested?(%Island{} = island) do
    MapSet.equal?(island.coords, island.hits)
  end

  @doc """
  Converts `island`'s origin into a CSS grid position.

  ## Examples

      iex> alias Islands.{Coord, Island}
      iex> {:ok, origin} = Coord.new(2, 3)
      iex> {:ok, atoll} = Island.new(:atoll, origin)
      iex> Island.grid_position(atoll)
      %{gridRowStart: 2, gridColumnStart: 3}
  """
  @spec grid_position(t) :: grid_position
  def grid_position(%Island{origin: %Coord{row: row, col: col}} = _island) do
    %{gridColumnStart: col, gridRowStart: row}
  end

  @doc """
  Returns a list of hit "cells" relative to the `island`'s origin.

  ## Examples

      iex> alias Islands.{Coord, Island}
      iex> {:ok, origin} = Coord.new(2, 2)
      iex> {:ok, atoll} = Island.new(:atoll, origin)
      iex> {:ok, a1} = Coord.new(2, 2)
      iex> {:ok, b1} = Coord.new(2, 3)
      iex> {:ok, a3} = Coord.new(4, 2)
      iex> {:hit, atoll} = Island.guess(atoll, a1)
      iex> {:hit, atoll} = Island.guess(atoll, b1)
      iex> {:hit, atoll} = Island.guess(atoll, a3)
      iex> Island.hit_cells(atoll) |> Enum.sort()
      ["a1", "a3", "b1"]
  """
  @spec hit_cells(t) :: [grid_cell]
  def hit_cells(%Island{origin: origin, hits: hits} = _island) do
    # <<?a, ?1>> is "a1", <<?a + 1, ?1 + 2>> is "b3", etc.
    Enum.map(hits, &<<?a + &1.col - origin.col, ?1 + &1.row - origin.row>>)
  end

  ## Private functions

  @spec coords(Offsets.t(), Coord.t()) :: [Coord.t()] | :error
  defp coords(offsets, %Coord{row: row, col: col} = _origin) do
    Enum.reduce_while(offsets, [], fn {row_offset, col_offset}, coords ->
      case Coord.new(row + row_offset, col + col_offset) do
        {:ok, coord} -> {:cont, [coord | coords]}
        {:error, _reason} -> {:halt, :error}
      end
    end)
  end

  ## Helpers

  defimpl Jason.Encoder, for: MapSet do
    @spec encode(%MapSet{}, Jason.Encode.opts()) :: iodata
    def encode(%MapSet{} = set, opts) do
      Enum.to_list(set) |> Jason.Encode.list(opts)
    end
  end
end
