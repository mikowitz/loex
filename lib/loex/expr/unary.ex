defmodule Loex.Expr.Unary do
  @moduledoc false

  defstruct [:operator, :expr]

  def new(op, expr), do: %__MODULE__{operator: op, expr: expr}
end
