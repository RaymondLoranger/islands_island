defmodule Islands.Island.Offsets do
  @moduledoc """
  Returns a list of offsets for each island type.
  """

  alias Islands.Island

  @type col_offset :: 0..2
  @type row_offset :: 0..2
  @type t :: [{row_offset, col_offset}]

  @doc """
  Returns a list of offsets for a given island type.
  """
  @spec new(Island.type()) :: t | {:error, atom}
  def new(island_type)
  def new(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  def new(:dot), do: [{0, 0}]
  def new(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  def new(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  def new(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  def new(_unknown), do: {:error, :invalid_island_type}
end
