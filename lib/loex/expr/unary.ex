defmodule Loex.Expr.Unary do
  @moduledoc false

  defstruct [:operator, :expr]

  def new(operator, expr), do: %__MODULE__{operator: operator, expr: expr}

  defimpl Loex.Expr do
    def to_string(%@for{operator: operator, expr: expr}) do
      "(#{operator.lexeme} #{@protocol.to_string(expr)})"
    end

    def evaluate(%@for{operator: %{type: :BANG}, expr: expr}, env) do
      case @protocol.evaluate(expr, env) do
        {b, env} when b in [false, nil] -> {true, env}
        {_, env} -> {false, env}
      end
    end

    def evaluate(%@for{operator: %{type: :MINUS, line: line}, expr: expr}, env) do
      case @protocol.evaluate(expr, env) do
        {n, env} when is_number(n) ->
          {-n, env}

        {_, env} ->
          Loex.error(line, "Operand to `-' must be a number")
          {nil, env}
      end
    end
  end
end
