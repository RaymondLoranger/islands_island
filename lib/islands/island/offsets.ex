defmodule Islands.Island.Offsets do
  @moduledoc """
  Returns a list of offset tuples for each island type.
  """

  alias Islands.Island

  @typedoc "Column offset"
  @type col_offset :: 0..2
  @typedoc "Row offset"
  @type row_offset :: 0..2
  @typedoc "A list of offset tuples"
  @type t :: [{row_offset, col_offset}]

  @doc """
  Returns a list of offset tuples for the given `island_type`.
  """
  @spec new(Island.type()) :: t | {:error, atom}
  def new(island_type)
  # **
  #  *
  # **
  def new(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  # *
  def new(:dot), do: [{0, 0}]
  # *
  # *
  # **
  def new(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  #  **
  # **
  def new(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  # **
  # **
  def new(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  def new(_unknown), do: {:error, :invalid_island_type}
end
