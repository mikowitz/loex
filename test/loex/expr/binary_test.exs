defmodule Loex.Expr.BinaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Loex.Expr
  alias Loex.Expr.{Binary, Primary}

  describe "valid expressions" do
    test "subtracting numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "-", Primary.new(1.05, 1), 1)
      assert Expr.evaluate(expr) == 7.05
    end

    test "dividing numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "/", Primary.new(1.05, 1), 1)
      assert Expr.evaluate(expr) == 7.7142857142857135
    end

    test "multiplying numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "*", Primary.new(1.05, 1), 1)
      assert Expr.evaluate(expr) == 8.505
    end

    test "adding numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "+", Primary.new(1.05, 1), 1)
      assert Expr.evaluate(expr) == 9.15
    end

    test "adding strings" do
      expr = Binary.new(Primary.new("hello, ", 1), "+", Primary.new("world", 1), 1)
      assert Expr.evaluate(expr) == "hello, world"
    end

    test "comparing numbers with >" do
      expr = Binary.new(Primary.new(3, 1), ">", Primary.new(2.9, 1), 1)
      assert Expr.evaluate(expr) == true
    end

    test "comparing numbers <" do
      expr = Binary.new(Primary.new(3, 1), "<", Primary.new(2.9, 1), 1)
      assert Expr.evaluate(expr) == false
    end

    test "equality check for strings" do
      expr = Binary.new(Primary.new("ok", 1), "==", Primary.new("ok", 1), 1)
      assert Expr.evaluate(expr) == true
    end
  end

  describe "invalid expressions" do
    test "trying to subtract a boolean" do
      expr = Binary.new(Primary.new(8.1, 1), "-", Primary.new(true, 1), 1)

      actual_stderr =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert actual_stderr =~ "[line 1] Error: Both operands to `-' must be numbers"
    end

    test "trying to subtract from a boolean" do
      expr = Binary.new(Primary.new(true, 1), "-", Primary.new(4, 1), 1)

      actual_stderr =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert actual_stderr =~ "[line 1] Error: Both operands to `-' must be numbers"
    end

    test "trying to add to a boolean" do
      expr = Binary.new(Primary.new(true, 1), "+", Primary.new("ok", 1), 1)

      actual_stderr =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert actual_stderr =~ "[line 1] Error: Both operands to `+' must be numbers or strings"
    end
  end
end
