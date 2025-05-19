defmodule Loex.Expr.Logical do
  defstruct [:left, :operator, :right]

  def new(left, operator, right) do
    %__MODULE__{left: left, operator: operator, right: right}
  end

  defimpl Loex.Expr do
    def to_string(%{left: l, operator: op, right: r}) do
      "(#{op.lexeme} #{@protocol.to_string(l)} #{@protocol.to_string(r)})"
    end

    def evaluate(%{left: l, operator: op, right: r}, env) do
      {left, env} = @protocol.evaluate(l, env)

      case op.type do
        :OR ->
          if left do
            {left, env}
          else
            @protocol.evaluate(r, env)
          end

        :AND ->
          if !left do
            {left, env}
          else
            @protocol.evaluate(r, env)
          end
      end
    end
  end
end
