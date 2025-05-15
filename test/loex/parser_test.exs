defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import Loex.Test.Support.ExpressionGenerators
  use ExUnitProperties

  alias Loex.{Expr, Parser, Token}

  describe "parse/1" do
    property "a valid expression" do
      check all {tokens, ast_str} <- expression() do
        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "an unclosed group" do
      check all {tokens, _} <- expression() do
        tokens = [Token.new(:LEFT_PAREN, "(", nil, 1) | tokens]

        error =
          capture_io(:stderr, fn ->
            parser = Parser.new(tokens) |> Parser.parse()
            assert parser.ast == nil
          end)

        assert error =~ "[line 1] Error: Expect `)' after expression."
      end
    end

    property "dangling operator" do
      check all {tokens, _} <- factor_expr(),
                {op_token, _} <- term_operator() do
        tokens = tokens ++ [op_token, Token.new(:EOF, "", nil, 1)]

        error =
          capture_io(:stderr, fn ->
            Parser.new(tokens) |> Parser.parse()
          end)

        assert error =~ "[line 1] Error: Unexpected EOF"
      end
    end

    property "comma operator" do
      check all {a, a_str} <- expression(),
                {b, b_str} <- expression(),
                {c, c_str} <- expression() do
        tokens =
          a ++
            [Token.new(:COMMA, ",", nil, 1)] ++
            b ++ [Token.new(:COMMA, ",", nil, 1)] ++ c

        ast_str = a_str <> " , " <> b_str <> " , " <> c_str

        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end

    property "ternary operator" do
      check all {a, a_str} <- expression(),
                {b, b_str} <- expression(),
                {c, c_str} <- expression() do
        tokens =
          a ++
            [Token.new(:QUESTION_MARK, "?", nil, 1)] ++
            b ++ [Token.new(:COLON, ":", nil, 1)] ++ c

        ast_str = a_str <> " ? " <> b_str <> " : " <> c_str

        parser = Parser.new(tokens) |> Parser.parse()
        assert Expr.to_string(parser.ast) == ast_str
      end
    end
  end
end
