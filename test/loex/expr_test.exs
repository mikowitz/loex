defmodule Loex.ExprTest do
  use ExUnit.Case, async: true

  use ExUnitProperties

  import Loex.Test.Support.ExpressionGenerators

  alias Loex.Expr

  describe "evaluating" do
    property "a literal expression" do
      check all %{value: value} = literal <- literal() do
        {evaluated, _env} = Expr.evaluate(literal)
        assert evaluated == value
      end
    end

    property "a grouping expression" do
      check all %{expr: %{value: value}} = grouping <- grouping() do
        {evaluated, _env} = Expr.evaluate(grouping)
        assert evaluated == value
      end
    end
  end
end
