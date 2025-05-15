defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import Loex.Test.Support.ExpressionGenerators
  use ExUnitProperties

  alias Loex.{Expr, Parser, Token}

  describe "parse/1" do
    property "a primary expression" do
      check all {token, ast_str} <- primary_expr() do
        parser = Parser.new([token]) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "a grouping expression" do
      check all {tokens, ast_str} <- grouping_expr() do
        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "an unclosed group" do
      check all {token, _} <- primary_expr() do
        tokens = [Token.new(:LEFT_PAREN, "(", nil, 1), token]

        error =
          capture_io(:stderr, fn ->
            parser = Parser.new(tokens) |> Parser.parse()
            assert parser.ast == nil
          end)

        assert error =~ "[line 1] Error: Expect `)' after expression."
      end
    end

    property "a unary expression" do
      check all {tokens, ast_str} <- unary_expr() do
        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "a factor expression" do
      check all {tokens, ast_str} <- factor_expr() do
        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "a term expression" do
      check all {tokens, ast_str} <- term_expr() do
        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end
  end
end
