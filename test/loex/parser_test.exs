defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

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
  end

  defp primary_expr do
    one_of([
      constant({Token.new(:TRUE, "true", nil, 1), "true"}),
      constant({Token.new(:FALSE, "false", nil, 1), "false"}),
      constant({Token.new(:NIL, "nil", nil, 1), "nil"}),
      one_of([
        float(min: 0.5, max: 999.5),
        integer(0..999)
      ])
      |> map(fn n -> {Token.new(:NUMBER, to_string(n), n * 1.0, 1), to_string(n * 1.0)} end),
      string(:ascii) |> map(fn s -> {Token.new(:STRING, s, s, 1), s} end)
    ])
  end

  defp grouping_expr do
    primary_expr()
    |> map(fn {token, str} ->
      {
        [Token.new(:LEFT_PAREN, "(", nil, 1), token, Token.new(:RIGHT_PAREN, ")", nil, 1)],
        "(group #{str})"
      }
    end)
  end

  defp unary_operator do
    one_of([
      constant({Token.new(:BANG, "!", nil, 1), "!"}),
      constant({Token.new(:MINUS, "-", nil, 1), "-"})
    ])
  end

  defp unary_expr do
    gen all {expr, expr_str} <- grouping_expr(),
            {op_token, op_str} <- unary_operator() do
      {[op_token | expr], "(#{op_str} #{expr_str})"}
    end
  end
end
