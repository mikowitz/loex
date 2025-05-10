defmodule Loex.Expr.Binary do
  @moduledoc false

  defstruct [:left, :op, :right, :line]

  def new(left, op, right, line) do
    %__MODULE__{
      left: left,
      op: op,
      right: right,
      line: line
    }
  end

  def evaluate(%__MODULE__{left: left, op: op, right: right, line: line}) do
    with {:ok, left} <- left.__struct__.evaluate(left),
         {:ok, right} <- right.__struct__.evaluate(right) do
      evaluate_expression(left, right, op, line)
    else
      error -> error
    end
  end

  defguardp are_numbers(a, b) when is_number(a) and is_number(b)

  defp evaluate_expression(left, right, "-", _) when are_numbers(left, right) do
    {:ok, left - right}
  end

  defp evaluate_expression(left, right, "/", _) when are_numbers(left, right) do
    {:ok, left / right}
  end

  defp evaluate_expression(left, right, "*", _) when are_numbers(left, right) do
    {:ok, left * right}
  end

  defp evaluate_expression(left, right, "==", _) do
    {:ok, left == right}
  end

  defp evaluate_expression(left, right, "!=", _) do
    {:ok, left == right}
  end

  defp evaluate_expression(left, right, ">", _) when are_numbers(left, right) do
    {:ok, left > right}
  end

  defp evaluate_expression(left, right, "<", _) when are_numbers(left, right) do
    {:ok, left < right}
  end

  defp evaluate_expression(left, right, ">", _) when are_numbers(left, right) do
    {:ok, left > right}
  end

  defp evaluate_expression(left, right, "<=", _) when are_numbers(left, right) do
    {:ok, left <= right}
  end

  defp evaluate_expression(left, right, ">=", _) when are_numbers(left, right) do
    {:ok, left >= right}
  end

  defp evaluate_expression(left, right, "+", _) when are_numbers(left, right) do
    {:ok, left + right}
  end

  defp evaluate_expression(left, right, "+", _) when is_binary(left) and is_binary(right) do
    {:ok, left <> right}
  end

  defp evaluate_expression(_, _, "+", line) do
    Loex.error(line, "Both operands to `+' must be numbers or strings")
    {:error, :bad_operand}
  end

  defp evaluate_expression(_, _, op, line) do
    Loex.error(line, "Both operands to `#{op}' must be numbers")
    {:error, :bad_operand}
  end

  defimpl String.Chars do
    def to_string(%@for{left: l, op: op, right: r}) do
      "(#{op} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end
  end

  defimpl Inspect do
    def inspect(%@for{} = binary, _opts), do: to_string(binary)
  end
end
