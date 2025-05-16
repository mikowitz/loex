defmodule Loex.Statement.Print do
  @moduledoc false

  defstruct [:expr]

  def new(expr), do: %__MODULE__{expr: expr}

  defimpl Loex.Statement do
    alias Loex.Expr

    def to_string(%@for{expr: expr}) do
      "(print #{Expr.to_string(expr)} ;)"
    end

    def interpret(%@for{expr: expr}) do
      value = Expr.evaluate(expr)

      if is_nil(value), do: IO.puts("nil"), else: IO.puts(Kernel.to_string(value))

      nil
    end
  end
end
