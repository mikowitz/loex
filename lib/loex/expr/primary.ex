defmodule Loex.Expr.Primary do
  @moduledoc false

  defstruct [:literal, :line]

  def new(literal, line), do: %__MODULE__{literal: literal, line: line}

  def evaluate(%__MODULE__{literal: literal}), do: {:ok, literal}

  defimpl String.Chars do
    def to_string(%@for{literal: nil}), do: "nil"
    def to_string(%@for{literal: lit}), do: @protocol.to_string(lit)
  end

  defimpl Inspect do
    def inspect(%@for{} = primary, _opts), do: to_string(primary)
  end
end
