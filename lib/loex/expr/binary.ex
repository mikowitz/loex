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

    defguardp are_numbers(a, b) when is_number(a) and is_number(b)

    def do_evaluate("==", left, right), do: left == right
    def do_evaluate("!=", left, right) when are_numbers(left, right), do: left != right
    def do_evaluate(">", left, right) when are_numbers(left, right), do: left > right
    def do_evaluate(">=", left, right) when are_numbers(left, right), do: left >= right
    def do_evaluate("<", left, right) when are_numbers(left, right), do: left < right
    def do_evaluate("<=", left, right) when are_numbers(left, right), do: left <= right
    def do_evaluate("-", left, right) when are_numbers(left, right), do: left - right

    def do_evaluate("/", left, right) when are_numbers(left, right) do
      if right == 0.0, do: raise("Division by 0"), else: left / right
    end

    def do_evaluate("*", left, right) when are_numbers(left, right), do: left * right

    def do_evaluate("+", left, right) do
      cond do
        is_number(left) and is_number(right) ->
          left + right

        is_binary(left) or is_binary(right) ->
          Kernel.to_string(left) <> Kernel.to_string(right)

        true ->
          raise("Both operands to `+' must be numbers or strings")
      end
    end

    def do_evaluate(op, _, _) do
      raise("Both operands to `#{op}' must be numbers")
    end
  end
end
