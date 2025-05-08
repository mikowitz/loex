defmodule Loex.Expr.Grouping do
  @moduledoc false

  defstruct [:expr]

  def new(expr), do: %__MODULE__{expr: expr}
end
