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

    test "subtracting a string" do
      expr = Binary.new(Literal.new(8.1), "-", Literal.new("1.05"))

      assert_raise RuntimeError, "Both operands to `-' must be numbers", fn ->
        Expr.evaluate(expr)
      end
    end

    test "subtracting from a string" do
      expr = Binary.new(Literal.new("8.1"), "-", Literal.new(1.05))

      assert_raise RuntimeError, "Both operands to `-' must be numbers", fn ->
        Expr.evaluate(expr)
      end
    end

    test "division" do
      expr = Binary.new(Literal.new(8.1), "/", Literal.new(1.05))
      assert Expr.evaluate(expr) == 7.7142857142857135
    end

    test "division with invalid arguments" do
      expr = Binary.new(Literal.new("8.1"), "/", Literal.new(1.05))

      assert_raise RuntimeError, "Both operands to `/' must be numbers", fn ->
        Expr.evaluate(expr)
      end
    end

    test "multiplication" do
      expr = Binary.new(Literal.new(8.1), "*", Literal.new(1.05))
      assert Expr.evaluate(expr) == 8.505
    end

    test "multiplication with invalid arguments" do
      expr = Binary.new(Literal.new("8.1"), "*", Literal.new(1.05))

      assert_raise RuntimeError, "Both operands to `*' must be numbers", fn ->
        Expr.evaluate(expr)
      end
    end

    test "adding numbers" do
      expr = Binary.new(Literal.new(8.1), "+", Literal.new(1.05))
      assert Expr.evaluate(expr) == 9.15
    end

    test "adding strings" do
      expr = Binary.new(Literal.new("hello, "), "+", Literal.new("world!"))
      assert Expr.evaluate(expr) == "hello, world!"
    end

    test "invalid addition arguments" do
      expr = Binary.new(Literal.new(true), "+", Literal.new(nil))

      assert_raise RuntimeError, "Both operands to `+' must be numbers or strings", fn ->
        Expr.evaluate(expr)
      end
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

    test "invalid comparison operands" do
      expr = Binary.new(Literal.new(true), ">", Literal.new(1.05))

      assert_raise RuntimeError, "Both operands to `>' must be numbers", fn ->
        Expr.evaluate(expr)
      end

      expr = Binary.new(Literal.new(8.1), "<", Literal.new(false))

      assert_raise RuntimeError, "Both operands to `<' must be numbers", fn ->
        Expr.evaluate(expr)
      end

      expr = Binary.new(Literal.new("foo"), ">=", Literal.new(1.05))

      assert_raise RuntimeError, "Both operands to `>=' must be numbers", fn ->
        Expr.evaluate(expr)
      end

      expr = Binary.new(Literal.new(8.1), "<=", Literal.new("bar"))

      assert_raise RuntimeError, "Both operands to `<=' must be numbers", fn ->
        Expr.evaluate(expr)
      end
    end
  end
end
