defmodule Loex.Statement.Expression do
  @moduledoc false

  defstruct [:expr]

  def new(expr), do: %__MODULE__{expr: expr}

  defimpl Loex.Statement do
    alias Loex.Expr

    def to_string(%@for{expr: expr}) do
      "(statement #{Expr.to_string(expr)} ;)"
    end

    def interpret(%@for{expr: expr}, env) do
      Expr.evaluate(expr, env)
    end
  end
end
