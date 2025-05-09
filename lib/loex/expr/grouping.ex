defmodule Loex.Expr.Grouping do
  @moduledoc false

  defstruct [:expr, :line]

  def new(expr, line), do: %__MODULE__{expr: expr, line: line}

  def evaluate(%__MODULE__{expr: expr}) do
    expr.__struct__.evaluate(expr)
  end

  defimpl String.Chars do
    def to_string(%@for{expr: expr}), do: "(group #{@protocol.to_string(expr)})"
  end

  defimpl Inspect do
    def inspect(%@for{} = grouping, _opts), do: to_string(grouping)
  end
end
