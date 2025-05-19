defmodule Loex.Expr.CommaSeriesTest do
  use ExUnit.Case, async: true

  alias Loex.Expr
  alias Loex.Expr.CommaSeries
  alias Loex.Expr.Literal

  describe "evaluate" do
    test "evaluates to the right-most expression" do
      expr = CommaSeries.new(Literal.new(3), Literal.new("5"))

      {value, _env} = Expr.evaluate(expr)
      assert value == "5"
    end

    test "evaluates to the right-most expression in the deepest nesting" do
      expr =
        CommaSeries.new(
          Literal.new(3),
          CommaSeries.new(Literal.new("5"), Literal.new(17.5))
        )

      {value, _env} = Expr.evaluate(expr)
      assert value == 17.5
    end
  end
end
