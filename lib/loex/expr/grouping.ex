defmodule Loex.Expr.Grouping do
  @moduledoc false

  defstruct [:expr]

  def new(expr), do: %__MODULE__{expr: expr}

  defimpl Loex.Expr do
    def to_string(%@for{expr: expr}) do
      "(group #{@protocol.to_string(expr)})"
    end

    def evaluate(%@for{expr: expr}) do
      @protocol.evaluate(expr)
    end
  end
end
