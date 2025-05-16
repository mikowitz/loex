defmodule Loex.ExprTest do
  use ExUnit.Case, async: true

  import Loex.Test.Support.ExpressionGenerators
  use ExUnitProperties

  alias Loex.Expr

  describe "evaluating" do
    property "a literal expression" do
      check all %{value: value} = literal <- literal() do
        assert Expr.evaluate(literal) == value
      end
    end

    property "a grouping expression" do
      check all %{expr: %{value: value}} = grouping <- grouping() do
        assert Expr.evaluate(grouping) == value
      end
    end
  end
end
