defmodule Loex.Expr.Unary do
  @moduledoc false

  defstruct [:operator, :expr, :line]

  def new(op, expr, line), do: %__MODULE__{operator: op, expr: expr, line: line}

  def evaluate(%__MODULE__{operator: "-", expr: expr}) do
    case expr.__struct__.evaluate(expr) do
      {:ok, result} ->
        case result do
          n when is_number(n) ->
            {:ok, -n}

          e ->
            Loex.error(expr.line, "Negated operand must be a number, got #{e}")
            {:error, :non_number_operand}
        end

      {:error, _} = error ->
        error
    end
  end

  defimpl String.Chars do
    def to_string(%@for{operator: op, expr: expr}) do
      "(" <> op <> " " <> @protocol.to_string(expr) <> ")"
    end
  end

  defimpl Inspect do
    def inspect(%@for{} = unary, _opts), do: to_string(unary)
  end
end
