defmodule Loex.Expr.BinaryTest do
  use ExUnit.Case, async: true

  alias Loex.Expr
  alias Loex.Expr.Binary
  alias Loex.Expr.Literal
  alias Loex.Expr.Unary

  describe "evaluate" do
    test "subtraction" do
      expr = Binary.new(Literal.new(8.1), "-", Literal.new(1.05))
      assert Expr.evaluate(expr) == 7.05
    end

    test "division" do
      expr = Binary.new(Literal.new(8.1), "/", Literal.new(1.05))
      assert Expr.evaluate(expr) == 7.7142857142857135
    end

    test "multiplication" do
      expr = Binary.new(Literal.new(8.1), "*", Literal.new(1.05))
      assert Expr.evaluate(expr) == 8.505
    end

    test "adding numbers" do
      expr = Binary.new(Literal.new(8.1), "+", Literal.new(1.05))
      assert Expr.evaluate(expr) == 9.15
    end

    test "adding strings" do
      expr = Binary.new(Literal.new("hello, "), "+", Literal.new("world!"))
      assert Expr.evaluate(expr) == "hello, world!"
    end

    test "comparing numbers" do
      expr = Binary.new(Literal.new(8.1), ">", Literal.new(1.05))
      assert Expr.evaluate(expr) == true

      expr = Binary.new(Literal.new(8.1), "<", Literal.new(1.05))
      assert Expr.evaluate(expr) == false

      expr = Binary.new(Literal.new(8.1), ">=", Literal.new(1.05))
      assert Expr.evaluate(expr) == true

      expr = Binary.new(Literal.new(8.1), "<=", Literal.new(1.05))
      assert Expr.evaluate(expr) == false

      expr = Binary.new(Literal.new(8.1), "!=", Literal.new(1.05))
      assert Expr.evaluate(expr) == true

      expr = Binary.new(Literal.new(8.1), "==", Literal.new(1.05))
      assert Expr.evaluate(expr) == false
    end
  end
end
