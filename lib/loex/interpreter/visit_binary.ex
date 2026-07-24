defmodule Loex.Interpreter.VisitBinary do
  @moduledoc false
  alias Loex.Interpreter

  defguard are_numbers(a, b) when is_number(a) and is_number(b)

  def visit_binary(interpreter, left, right, %{type: :MINUS} = _op)
      when are_numbers(left, right),
      do: {left - right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :SLASH} = _op)
      when are_numbers(left, right),
      do: {left / right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :STAR} = _op) when are_numbers(left, right),
    do: {left * right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :GREATER} = _op)
      when are_numbers(left, right),
      do: {left > right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :GREATER_EQUAL} = _op)
      when are_numbers(left, right),
      do: {left >= right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :LESS} = _op) when are_numbers(left, right),
    do: {left < right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :LESS_EQUAL} = _op)
      when are_numbers(left, right),
      do: {left <= right, interpreter}

  def visit_binary(interpreter, _left, _right, %{type: t} = op)
      when t in [:MINUS, :SLASH, :STAR, :GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL],
      do: Interpreter.report_runtime_error(interpreter, op, "Operands must be numbers.")

  def visit_binary(interpreter, left, right, %{type: :PLUS} = _op)
      when are_numbers(left, right),
      do: {left + right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :PLUS} = _op)
      when is_bitstring(left) and is_bitstring(right),
      do: {left <> right, interpreter}

  def visit_binary(interpreter, _left, _right, %{type: :PLUS} = op),
    do:
      Interpreter.report_runtime_error(
        interpreter,
        op,
        "Operands must be two numbers or two strings."
      )

  def visit_binary(interpreter, left, right, %{type: :BANG_EQUAL}),
    do: {left != right, interpreter}

  def visit_binary(interpreter, left, right, %{type: :EQUAL_EQUAL}),
    do: {left == right, interpreter}
end
