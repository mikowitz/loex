defmodule Loex.Expr.Binary do
  @moduledoc false

  defstruct [:left, :operator, :right]

  def new(left, operator, right) do
    %__MODULE__{left: left, operator: operator, right: right}
  end

  defimpl Loex.Expr do
    def to_string(%@for{left: l, operator: op, right: r}) do
      "(#{op} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end
  end
end
