defmodule Loex.Statement.VariableDeclaration do
  @moduledoc false

  defstruct [:name, :expr]

  def new(name, expr) do
    %__MODULE__{name: name, expr: expr}
  end

  defimpl Loex.Statement do
    alias Loex.Environment
    alias Loex.Expr

    def to_string(%@for{name: name, expr: nil}) do
      "(var= #{name} ;)"
    end

    def to_string(%@for{name: name, expr: expr}) do
      "(var= #{name} #{Expr.to_string(expr)} ;)"
    end

    def interpret(%@for{name: name, expr: expr}, env) do
      value = Expr.evaluate(expr)
      {value, Environment.put(env, name, value)}
    end
  end
end
