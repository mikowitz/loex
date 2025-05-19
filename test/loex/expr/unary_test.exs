defmodule Loex.Expr.UnaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Loex.Expr
  alias Loex.Expr.{Literal, Unary}
  alias Loex.Token

  describe "evaluate" do
    test "negating a number" do
      expr = Unary.new(%Token{type: :MINUS, lexeme: "-", line: 7}, Literal.new(3.5))
      {value, _env} = Expr.evaluate(expr)
      assert value == -3.5
    end

    test "negating a boolean" do
      expr = Unary.new(%Token{type: :MINUS, lexeme: "-", line: 7}, Literal.new(true))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 7] Error: Operand to `-' must be a number"
    end

    test "negating a string" do
      expr = Unary.new(%Token{type: :MINUS, lexeme: "-", line: 4}, Literal.new("not a number!"))

      output =
        capture_io(:stderr, fn ->
          Expr.evaluate(expr)
        end)

      assert output =~ "[line 4] Error: Operand to `-' must be a number"
    end

    test "not true" do
      expr = Unary.new(%Token{type: :BANG, lexeme: "!"}, Literal.new(true))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end

    test "not false" do
      expr = Unary.new(%Token{type: :BANG, lexeme: "!"}, Literal.new(false))
      {value, _env} = Expr.evaluate(expr)
      assert value == true
    end

    test "not nil" do
      expr = Unary.new(%Token{type: :BANG, lexeme: "!"}, Literal.new(nil))
      {value, _env} = Expr.evaluate(expr)
      assert value == true
    end

    test "not a number" do
      expr = Unary.new(%Token{type: :BANG, lexeme: "!"}, Literal.new(3.5))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end

    test "not a string" do
      expr = Unary.new(%Token{type: :BANG, lexeme: "!"}, Literal.new("ok"))
      {value, _env} = Expr.evaluate(expr)
      assert value == false
    end
  end
end
