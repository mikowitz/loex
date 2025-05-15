defmodule Loex.Expr.Literal do
  @moduledoc false

  defstruct [:value]

  def new(value), do: %__MODULE__{value: value}

  defimpl Loex.Expr do
    def to_string(%@for{value: nil}), do: "nil"
    def to_string(%@for{value: value}), do: String.Chars.to_string(value)
  end
end
