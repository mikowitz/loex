defmodule Loex.Expr.UnaryTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Loex.Expr
  alias Loex.Expr.Primary
  alias Loex.Expr.Unary

  describe "evaluate" do
    test "negating a numerical expression" do
      expr = Unary.new("-", Primary.new(3.5, 1), 1)

      assert Expr.evaluate(expr) == -3.5
    end

    test "negating an integer expression" do
      expr = Unary.new("-", Primary.new(103, 1), 1)

      assert Expr.evaluate(expr) == -103.0
    end

    test "trying to negate a string" do
      expr = Unary.new("-", Primary.new("ok", 3), 3)

      assert capture_io(:stderr, fn ->
               Expr.evaluate(expr)
             end) == "[line 3] Error: Negated operand must be a number, got ok\n"
    end

    test "trying to negate a boolean" do
      expr = Unary.new("-", Primary.new(true, 2), 2)

      assert capture_io(:stderr, fn ->
               Expr.evaluate(expr)
             end) == "[line 2] Error: Negated operand must be a number, got true\n"
    end
  end
end
