defmodule Loex.Expr.Ternary do
  @moduledoc false

  defstruct [:condition, :left, :right]

  def new(condition, left, right) do
    %__MODULE__{condition: condition, left: left, right: right}
  end

  defimpl Loex.Expr do
    def to_string(%@for{condition: condition, left: left, right: right}) do
      [
        @protocol.to_string(condition),
        "?",
        @protocol.to_string(left),
        ":",
        @protocol.to_string(right)
      ]
      |> Enum.join(" ")
    end
  end
end
