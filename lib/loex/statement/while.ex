defmodule Loex.Statement.While do
  @moduledoc false

  defstruct [:condition, :body]

  def new(condition, body), do: %__MODULE__{condition: condition, body: body}

  defimpl Loex.Statement do
    def to_string(%@for{condition: c, body: b}) do
      "(while #{@protocol.to_string(c)} #{@protocol.to_string(b)})"
    end

    def interpret(%@for{condition: c, body: b}, env) do
      do_interpret(c, b, env)
    end

    defp do_interpret(c, b, env) do
      {c_eval, env} = Loex.Expr.evaluate(c, env)

      if c_eval do
        {_b_eval, env} = Loex.Statement.interpret(b, env)
        do_interpret(c, b, env)
      else
        {nil, env}
      end
    end
  end
end
