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
  end
end
