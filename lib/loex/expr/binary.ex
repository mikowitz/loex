defmodule Loex.Expr.Binary do
  @moduledoc false

  defstruct [:left, :op, :right]

  def new(left, op, right) do
    %__MODULE__{
      left: left,
      op: op,
      right: right
    }
  end
end
