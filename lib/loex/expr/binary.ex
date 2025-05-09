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

  def evaluate(%__MODULE__{left: left, op: op, right: right}) do
    with {:ok, left} <- left.__struct__.evaluate(left),
         {:ok, right} <- right.__struct__.evaluate(right) do
      case op do
        "-" ->
          {:ok, left - right}

        "/" ->
          {:ok, left / right}

        "*" ->
          {:ok, left * right}

        "+" ->
          cond do
            is_number(left) and is_number(right) -> {:ok, left + right}
            is_binary(left) and is_binary(right) -> {:ok, left <> right}
          end
      end
    else
      error -> error
    end
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
