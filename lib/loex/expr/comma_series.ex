defmodule Loex.Expr.CommaSeries do
  @moduledoc false

  defstruct [:left, :right]

  def new(left, right), do: %__MODULE__{left: left, right: right}

  defimpl Loex.Expr do
    def to_string(%@for{left: left, right: right}) do
      "#{@protocol.to_string(left)} , #{@protocol.to_string(right)}"
    end

    def evaluate(%@for{left: left, right: right}, env) do
      {_, env} = @protocol.evaluate(left, env)
      @protocol.evaluate(right, env)
    end
  end
end
