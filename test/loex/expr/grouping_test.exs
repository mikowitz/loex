defmodule Loex.Expr.GroupingTest do
  use ExUnit.Case, async: true

  import ExUnitProperties

  import LoexTest.Support.Generators

  alias Loex.Expr
  alias Loex.Expr.{Grouping, Primary}

  describe "evaluate" do
    property "correctly evaluates to the literal value" do
      check all input <- literal_expr() do
        expr = Grouping.new(Primary.new(input, 1), 1)
        assert Expr.evaluate(expr) == input
      end
    end
  end
end
