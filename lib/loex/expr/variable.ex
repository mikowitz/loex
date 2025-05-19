defmodule Loex.Expr.Variable do
  @moduledoc false

  defstruct [:name]

  def new(name), do: %__MODULE__{name: name}

  defimpl Loex.Expr do
    alias Loex.Environment
    def to_string(%@for{name: name}), do: "(variable \"#{name}\")"

    def evaluate(%@for{name: name}, env) do
      {Environment.get(env, name), env}
    end
  end
end
