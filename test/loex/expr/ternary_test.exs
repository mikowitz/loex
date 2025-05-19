defmodule Loex.Expr.TernaryTest do
  use ExUnit.Case, async: true

  alias Loex.Expr
  alias Loex.Expr.Literal
  alias Loex.Expr.Ternary

  describe "evaluate" do
    test "when the condition is true" do
      expr =
        Ternary.new(
          Literal.new(true),
          Literal.new(1),
          Literal.new(0)
        )

      {value, _env} = Expr.evaluate(expr)
      assert value == 1
    end

    test "when the condition is false" do
      expr =
        Ternary.new(
          Literal.new(false),
          Literal.new(1),
          Literal.new(0)
        )

      {value, _env} = Expr.evaluate(expr)
      assert value == 0
    end
  end
end
