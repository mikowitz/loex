defmodule Loex.Expr.Unary do
  @moduledoc false

  defstruct [:operator, :expr]

  def new(operator, expr), do: %__MODULE__{operator: operator, expr: expr}

  defimpl Loex.Expr do
    def to_string(%@for{operator: operator, expr: expr}) do
      "(#{operator} #{@protocol.to_string(expr)})"
    end

    def evaluate(%@for{operator: "!", expr: expr}, env) do
      case @protocol.evaluate(expr, env) do
        false -> true
        nil -> true
        _ -> false
      end
    end

    def evaluate(%@for{operator: "-", expr: expr}, env) do
      case @protocol.evaluate(expr, env) do
        n when is_number(n) -> -n
        _ -> raise("Operand to `-' must be a number")
      end
    end
  end
end
