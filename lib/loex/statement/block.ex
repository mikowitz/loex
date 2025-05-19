defmodule Loex.Statement.Block do
  @moduledoc false

  defstruct [:statements]

  def new(statements), do: %__MODULE__{statements: statements}

  defimpl Loex.Statement do
    alias Loex.Environment
    alias Loex.Statement

    def to_string(%@for{statements: statements}) do
      "(block #{length(statements)})"
    end

    def interpret(%@for{statements: statements}, env) do
      env = %Environment{env | outer: env}

      env =
        Enum.reduce(statements, env, fn stmt, env ->
          {_, env} = Statement.interpret(stmt, env)
          env
        end)

      {nil, env.outer}
    end
  end
end
