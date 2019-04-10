# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Island do
  use PersistConfig

  @book_ref Application.get_env(@app, :book_ref)

  @moduledoc """
  Models an `island` in the _Game of Islands_.
  \n##### #{@book_ref}
  """

  alias __MODULE__
  alias __MODULE__.Offsets
  alias Islands.Coord

  @types [:atoll, :dot, :l_shape, :s_shape, :square]

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:type, :coords, :hits]
  defstruct [:type, :coords, :hits]

  @type coords :: MapSet.t(Coord.t())
  @type t :: %Island{type: type, coords: coords, hits: coords}
  @type type :: :atoll | :dot | :l_shape | :s_shape | :square

  @spec new(type, Coord.t()) :: {:ok, t} | {:error, atom}
  def new(type, %Coord{} = origin) when type in @types do
    with [_ | _] = coords <- type |> Offsets.new() |> coords(origin) do
      {:ok, %Island{type: type, coords: MapSet.new(coords), hits: MapSet.new()}}
    else
      :error -> {:error, :invalid_island_location}
    end
  end

  def new(_type, _origin), do: {:error, :invalid_island_args}

  @spec overlaps?(t, t) :: boolean
  def overlaps?(%Island{} = new_island, %Island{} = island) do
    not MapSet.disjoint?(new_island.coords, island.coords)
  end

  @spec guess(t, Coord.t()) :: {:hit, t} | :miss
  def guess(%Island{} = island, %Coord{} = guess) do
    if MapSet.member?(island.coords, guess),
      do: {:hit, update_in(island.hits, &MapSet.put(&1, guess))},
      else: :miss
  end

  @spec forested?(t) :: boolean
  def forested?(%Island{} = island) do
    MapSet.equal?(island.coords, island.hits)
  end

  defimpl Jason.Encoder, for: MapSet do
    def encode(struct, opts) do
      struct |> Enum.to_list() |> Jason.Encode.list(opts)
    end
  end

  ## Private functions

  @spec coords([tuple], Coord.t()) :: [Coord.t()] | :error
  defp coords(offsets, %Coord{row: row, col: col} = _origin) do
    Enum.reduce_while(offsets, [], fn {row_offset, col_offset}, coords ->
      case Coord.new(row + row_offset, col + col_offset) do
        {:ok, coord} -> {:cont, [coord | coords]}
        {:error, _reason} -> {:halt, :error}
      end
    end)
  end
end
