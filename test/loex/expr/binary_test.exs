defmodule Loex.Expr.BinaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Loex.Expr
  alias Loex.Expr.Binary
  alias Loex.Expr.Literal
  alias Loex.Token

  describe "evaluate" do
    test "subtraction" do
      expr = Binary.new(Literal.new(8.1), Token.new(:MINUS, "-", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == 7.05
    end

    test "subtracting a string" do
      expr = Binary.new(Literal.new(8.1), Token.new(:MINUS, "-", nil, 1), Literal.new("1.05"))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `-' must be numbers"
    end

    test "subtracting from a string" do
      expr = Binary.new(Literal.new("8.1"), Token.new(:MINUS, "-", nil, 1), Literal.new(1.05))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `-' must be numbers"
    end

    test "division" do
      expr = Binary.new(Literal.new(8.1), Token.new(:SLASH, "/", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == 7.7142857142857135
    end

    test "division with invalid arguments" do
      expr = Binary.new(Literal.new("8.1"), Token.new(:SLASH, "/", nil, 1), Literal.new(1.05))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `/' must be numbers"
    end

    test "division by zero" do
      expr = Binary.new(Literal.new(0), Token.new(:SLASH, "/", nil, 1), Literal.new(0))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Division by 0"
    end

    test "multiplication" do
      expr = Binary.new(Literal.new(8.1), Token.new(:STAR, "*", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == 8.505
    end

    test "multiplication with invalid arguments" do
      expr = Binary.new(Literal.new("8.1"), Token.new(:STAR, "*", nil, 1), Literal.new(1.05))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `*' must be numbers"
    end

    test "adding numbers" do
      expr = Binary.new(Literal.new(8.1), Token.new(:PLUS, "+", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == 9.15
    end

    test "adding strings" do
      expr =
        Binary.new(Literal.new("hello, "), Token.new(:PLUS, "+", nil, 1), Literal.new("world!"))

      assert Expr.evaluate(expr) == "hello, world!"
    end

    test "adding anything to a string" do
      expr =
        Binary.new(Literal.new("hello, "), Token.new(:PLUS, "+", nil, 1), Literal.new(3.14159))

      assert Expr.evaluate(expr) == "hello, 3.14159"
    end

    test "adding a string to anything" do
      expr = Binary.new(Literal.new(true), Token.new(:PLUS, "+", nil, 1), Literal.new(", world!"))
      assert Expr.evaluate(expr) == "true, world!"
    end

    test "invalid addition arguments" do
      expr = Binary.new(Literal.new(true), Token.new(:PLUS, "+", nil, 1), Literal.new(nil))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `+' must be numbers or strings"
    end

    test "comparing numbers" do
      expr = Binary.new(Literal.new(8.1), Token.new(:GREATER, ">", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == true

      expr = Binary.new(Literal.new(8.1), Token.new(:LESS, "<", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == false

      expr =
        Binary.new(Literal.new(8.1), Token.new(:GREATER_EQUAL, ">=", nil, 1), Literal.new(1.05))

      assert Expr.evaluate(expr) == true

      expr = Binary.new(Literal.new(8.1), Token.new(:LESS_EQUAL, "<=", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == false

      expr = Binary.new(Literal.new(8.1), Token.new(:BANG_EQUAL, "!=", nil, 1), Literal.new(1.05))
      assert Expr.evaluate(expr) == true

      expr =
        Binary.new(Literal.new(8.1), Token.new(:EQUAL_EQUAL, "==", nil, 1), Literal.new(1.05))

      assert Expr.evaluate(expr) == false
    end

    test "invalid comparison operands" do
      expr = Binary.new(Literal.new(true), Token.new(:GREATER, ">", nil, 1), Literal.new(1.05))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `>' must be numbers"

      expr = Binary.new(Literal.new(8.1), Token.new(:LESS, "<", nil, 1), Literal.new(false))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `<' must be numbers"

      expr =
        Binary.new(Literal.new("foo"), Token.new(:GREATER_EQUAL, ">=", nil, 1), Literal.new(1.05))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `>=' must be numbers"

      expr =
        Binary.new(Literal.new(8.1), Token.new(:LESS_EQUAL, "<=", nil, 1), Literal.new("bar"))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 1] Error: Both operands to `<=' must be numbers"
    end
  end
end
