defmodule Loex.Expr.UnaryTest do
  use ExUnit.Case, async: true

  alias Loex.Expr
  alias Loex.Expr.Literal
  alias Loex.Expr.Unary

  describe "evaluate" do
    test "negating a number" do
      expr = Unary.new("-", Literal.new(3.5))
      assert Expr.evaluate(expr) == -3.5
    end

    test "not true" do
      expr = Unary.new("!", Literal.new(true))
      assert Expr.evaluate(expr) == false
    end

    test "not false" do
      expr = Unary.new("!", Literal.new(false))
      assert Expr.evaluate(expr) == true
    end

    test "not nil" do
      expr = Unary.new("!", Literal.new(nil))
      assert Expr.evaluate(expr) == true
    end

    test "not a number" do
      expr = Unary.new("!", Literal.new(3.5))
      assert Expr.evaluate(expr) == false
    end

    test "not a string" do
      expr = Unary.new("!", Literal.new("ok"))
      assert Expr.evaluate(expr) == false
    end
  end
end
