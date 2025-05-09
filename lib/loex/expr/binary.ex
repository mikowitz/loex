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

  defimpl String.Chars do
    def to_string(%@for{left: l, op: op, right: r}) do
      "(#{op} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end
  end

  defimpl Inspect do
    def inspect(%@for{} = binary, _opts), do: to_string(binary)
  end
end
