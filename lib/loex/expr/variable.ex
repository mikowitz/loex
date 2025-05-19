defmodule Loex.Expr.Variable do
  @moduledoc false

  defstruct [:name, :line]

  def new(name, line), do: %__MODULE__{name: name, line: line}

  defimpl Loex.Expr do
    alias Loex.Environment
    def to_string(%@for{name: name}), do: "(variable \"#{name}\")"

    def evaluate(%@for{name: name, line: line}, env) do
      {Environment.get(env, name, line), env}
    end
  end
end
