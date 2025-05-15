defmodule Loex.Expr.Unary do
  @moduledoc false

  defstruct [:operator, :expr]

  def new(operator, expr), do: %__MODULE__{operator: operator, expr: expr}

  defimpl Loex.Expr do
    def to_string(%@for{operator: operator, expr: expr}) do
      "(#{operator} #{@protocol.to_string(expr)})"
    end
  end
end
