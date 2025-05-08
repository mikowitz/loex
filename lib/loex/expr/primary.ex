defmodule Loex.Expr.Primary do
  @moduledoc false

  defstruct [:literal]

  def new(literal), do: %__MODULE__{literal: literal}
end
