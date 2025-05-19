defmodule Loex.Expr.Binary do
  @moduledoc false

  defstruct [:left, :operator, :right]

  def new(left, operator, right) do
    %__MODULE__{left: left, operator: operator, right: right}
  end

  defimpl Loex.Expr do
    def to_string(%@for{left: l, operator: op, right: r}) do
      "(#{op.lexeme} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end

    def evaluate(%{left: left, operator: op, right: right}, env) do
      {left, env} = @protocol.evaluate(left, env)
      {right, env} = @protocol.evaluate(right, env)

      {do_evaluate(op.lexeme, left, right, op.line), env}
    end

    defguardp are_numbers(a, b) when is_number(a) and is_number(b)

    def do_evaluate("==", left, right, _), do: left == right
    def do_evaluate("!=", left, right, _) when are_numbers(left, right), do: left != right
    def do_evaluate(">", left, right, _) when are_numbers(left, right), do: left > right
    def do_evaluate(">=", left, right, _) when are_numbers(left, right), do: left >= right
    def do_evaluate("<", left, right, _) when are_numbers(left, right), do: left < right
    def do_evaluate("<=", left, right, _) when are_numbers(left, right), do: left <= right
    def do_evaluate("-", left, right, _) when are_numbers(left, right), do: left - right

    def do_evaluate("/", left, right, line) when are_numbers(left, right) do
      if right != 0.0 do
        left / right
      else
        Loex.error(line, "Division by 0")
      end
    end

    def do_evaluate("*", left, right, _) when are_numbers(left, right), do: left * right

    def do_evaluate("+", left, right, line) do
      cond do
        is_number(left) and is_number(right) ->
          left + right

        is_binary(left) or is_binary(right) ->
          Kernel.to_string(left) <> Kernel.to_string(right)

        true ->
          Loex.error(line, "Both operands to `+' must be numbers or strings")
      end
    end

    def do_evaluate(op, _, _, line) do
      Loex.error(line, "Both operands to `#{op}' must be numbers")
    end
  end
end
