defmodule Loex.Expr.Binary do
  @moduledoc false

  defstruct [:left, :operator, :right]

  def new(left, operator, right) do
    %__MODULE__{left: left, operator: operator, right: right}
  end

  defimpl Loex.Expr do
    def to_string(%@for{left: l, operator: op, right: r}) do
      "(#{op} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end

    def evaluate(%{left: left, operator: op, right: right}) do
      left = @protocol.evaluate(left)
      right = @protocol.evaluate(right)

      do_evaluate(op, left, right)
    end

    def do_evaluate("==", left, right), do: left == right
    def do_evaluate("!=", left, right), do: left != right
    def do_evaluate(">", left, right), do: left > right
    def do_evaluate(">=", left, right), do: left >= right
    def do_evaluate("<", left, right), do: left < right
    def do_evaluate("<=", left, right), do: left <= right
    def do_evaluate("-", left, right), do: left - right
    def do_evaluate("/", left, right), do: left / right
    def do_evaluate("*", left, right), do: left * right

    def do_evaluate("+", left, right) do
      cond do
        is_number(left) and is_number(right) ->
          left + right

        is_binary(left) and is_binary(right) ->
          left <> right

        true ->
          Loex.error(100, "Both operands to `+' must be numbers or strings")
      end
    end
  end
end
