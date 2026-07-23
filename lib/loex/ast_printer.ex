defmodule Loex.AstPrinter do
  @moduledoc "A simple AST Printer for Lox programs."

  defstruct []

  def print(%__MODULE__{} = printer, expr) do
    expr.__struct__.accept(expr, printer)
  end

  def visit(%__MODULE__{} = printer, %Loex.Expr.Binary{} = expr) do
    parenthesize(printer, expr.operator.lexeme, [expr.left, expr.right])
  end

  def visit(%__MODULE__{} = printer, %Loex.Expr.Grouping{} = expr) do
    parenthesize(printer, "group", [expr.expression])
  end

  def visit(%__MODULE__{} = printer, %Loex.Expr.Unary{} = expr) do
    parenthesize(printer, expr.operator.lexeme, [expr.right])
  end

  def visit(%__MODULE__{} = _printer, %Loex.Expr.Literal{} = expr) do
    case is_nil(expr.value) do
      true -> "nil"
      false -> expr.value
    end
  end

  defp parenthesize(%__MODULE__{} = printer, name, exprs) do
    [
      "(",
      name,
      " ",
      Enum.map_join(exprs, " ", & &1.__struct__.accept(&1, printer)),
      ")"
    ]
    |> List.flatten()
    |> Enum.join("")
  end
end
