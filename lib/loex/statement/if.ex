defmodule Loex.Statement.If do
  @moduledoc false

  defstruct [:condition, :then_branch, :else_branch]

  def new(condition, then_branch, else_branch) do
    %__MODULE__{condition: condition, then_branch: then_branch, else_branch: else_branch}
  end

  defimpl Loex.Statement do
    def to_string(%@for{condition: c, then_branch: t, else_branch: e}) do
      str = "(if #{@protocol.to_string(c)} then #{@protocol.to_string(t)}"

      if is_nil(e) do
        str <> ")"
      else
        str <> " else #{@protocol.to_string(e)})"
      end
    end

    def interpret(%@for{condition: c, then_branch: t, else_branch: e}, env) do
      {c, env} = Loex.Expr.evaluate(c, env)

      if c do
        @protocol.interpret(t, env)
      else
        if !is_nil(e), do: @protocol.interpret(e, env)
      end
    end
  end
end
