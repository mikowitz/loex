defmodule Loex.Expr.BinaryTest do
  use ExUnit.Case, async: true

  alias Loex.Expr
  alias Loex.Expr.{Binary, Primary}

  describe "valid expressions" do
    test "subtracting numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "-", Primary.new(1.05, 1))
      assert Expr.evaluate(expr) == 7.05
    end

    test "dividing numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "/", Primary.new(1.05, 1))
      assert Expr.evaluate(expr) == 7.7142857142857135
    end

    test "multiplying numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "*", Primary.new(1.05, 1))
      assert Expr.evaluate(expr) == 8.505
    end

    test "adding numbers" do
      expr = Binary.new(Primary.new(8.1, 1), "+", Primary.new(1.05, 1))
      assert Expr.evaluate(expr) == 9.15
    end

    test "adding strings" do
      expr = Binary.new(Primary.new("hello, ", 1), "+", Primary.new("world", 1))
      assert Expr.evaluate(expr) == "hello, world"
    end
  end
end
