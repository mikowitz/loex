defmodule Loex.Interpreter do
  @moduledoc """
  Interprets a [Loex.Expr] to its value.
  """

  defstruct [:runtime]

  alias Loex.Expr.{Binary, Grouping, Literal, Unary}
  alias Loex.Interpreter.VisitBinary
  alias Loex.Stmt.{Expression, Print}

  def new(runtime \\ %Loex{}) do
    %__MODULE__{runtime: runtime}
  end

  def interpret(%__MODULE__{} = interpreter, statements) do
    Enum.reduce(statements, interpreter, fn stmt, interpreter ->
      {_, interpreter} = execute(interpreter, stmt)
      interpreter
    end)
  end

  def execute(%__MODULE__{} = interpreter, stmt) do
    stmt.__struct__.accept(stmt, interpreter)
  end

  def evaluate(%__MODULE__{} = interpreter, expr) do
    expr.__struct__.accept(expr, interpreter)
  end

  defguard are_numbers(a, b) when is_number(a) and is_number(b)

  def visit(%__MODULE__{} = interpreter, %Expression{} = stmt) do
    {_, interpreter} = evaluate(interpreter, stmt.expression)
    {nil, interpreter}
  end

  def visit(%__MODULE__{} = interpreter, %Print{} = stmt) do
    {value, interpreter} = evaluate(interpreter, stmt.expression)
    IO.puts(value)
    {nil, interpreter}
  end

  def visit(%__MODULE__{} = interpreter, %Binary{} = expr) do
    {left, interpreter} = evaluate(interpreter, expr.left)
    {right, interpreter} = evaluate(interpreter, expr.right)

    VisitBinary.visit_binary(interpreter, left, right, expr.operator)
  end

  def visit(%__MODULE__{} = interpreter, %Grouping{} = expr) do
    evaluate(interpreter, expr.expression)
  end

  def visit(%__MODULE__{} = interpreter, %Literal{} = expr) do
    {expr.value, interpreter}
  end

  def visit(%__MODULE__{} = interpreter, %Unary{} = expr) do
    {right, interpreter} = evaluate(interpreter, expr.right)

    case expr.operator.type do
      :BANG -> {!right, interpreter}
      :MINUS when is_number(right) -> {-right, interpreter}
      :MINUS -> report_runtime_error(interpreter, expr.operator, "Operand must be a number.")
      _ -> nil
    end
  end

  def report_runtime_error(%__MODULE__{runtime: runtime} = interpreter, token, message) do
    runtime = Loex.runtime_error(runtime, token, message)
    {nil, %{interpreter | runtime: runtime}}
  end
end
