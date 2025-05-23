defmodule Loex.Expr.Assign do
  @moduledoc false

  defstruct [:name, :value]

  def new(name, value), do: %__MODULE__{name: name, value: value}

  defimpl Loex.Expr do
    alias Loex.Environment
    alias Loex.Expr
    alias Loex.Expr.Variable

    def to_string(%@for{name: name, value: value}) do
      "(var= #{Expr.to_string(name)} #{Expr.to_string(value)} ;)"
    end

    def evaluate(%@for{name: %Variable{name: name, line: line}, value: value}, env) do
      {value, env} = Expr.evaluate(value, env)
      env = Environment.put(env, name, value, line)
      {value, env}
    end
  end
end
