defmodule Loex.Expr.UnaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Loex.Expr
  alias Loex.Expr.Literal
  alias Loex.Expr.Unary

  describe "evaluate" do
    test "negating a number" do
      expr = Unary.new("-", Literal.new(3.5))
      {value, _env} = Expr.evaluate(expr)
      assert value == -3.5
    end

    test "negating a boolean" do
      expr = Unary.new("-", Literal.new(true))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "Operand to `-' must be a number"
    end

    test "negating a string" do
      expr = Unary.new("-", Literal.new("whatever"))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "Operand to `-' must be a number"
    end

    test "not true" do
      expr = Unary.new("!", Literal.new(true))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end

    test "not false" do
      expr = Unary.new("!", Literal.new(false))
      {value, _env} = Expr.evaluate(expr)
      assert value == true
    end

    test "not nil" do
      expr = Unary.new("!", Literal.new(nil))
      {value, _env} = Expr.evaluate(expr)
      assert value == true
    end

    test "not a number" do
      expr = Unary.new("!", Literal.new(3.5))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end

    test "not a string" do
      expr = Unary.new("!", Literal.new("ok"))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end
  end
end
