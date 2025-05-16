defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import Loex.Test.Support.ExpressionGenerators
  use ExUnitProperties

  alias Loex.{Parser, Statement, Token}

  describe "parse/1" do
    property "a valid expression" do
      check all {tokens, ast_str} <- expression() do
        tokens =
          tokens ++
            [
              Token.new(:SEMICOLON, ",", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == "(statement #{ast_str} ;)"
      end
    end

    property "an unclosed group" do
      check all {tokens, _} <- expression() do
        tokens =
          [Token.new(:LEFT_PAREN, "(", nil, 1) | tokens] ++
            [
              Token.new(:EOF, "", nil, 1)
            ]

        error =
          capture_io(:stderr, fn ->
            Parser.new(tokens) |> Parser.parse()
          end)

        assert error =~ "[line 1] Error: Expect `;' after value"
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

        assert error =~ "[line 1] Error: Expect `;' after value"
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
            b ++
            [Token.new(:COMMA, ",", nil, 1)] ++
            c ++
            [
              Token.new(:SEMICOLON, ";", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        ast_str = "(statement " <> a_str <> " , " <> b_str <> " , " <> c_str <> " ;)"

        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == ast_str
      end
    end

    property "ternary operator" do
      check all {a, a_str} <- expression(),
                {b, b_str} <- expression(),
                {c, c_str} <- expression() do
        tokens =
          a ++
            [Token.new(:QUESTION_MARK, "?", nil, 1)] ++
            b ++
            [Token.new(:COLON, ":", nil, 1)] ++
            c ++
            [
              Token.new(:SEMICOLON, ";", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        ast_str = "(statement " <> a_str <> " ? " <> b_str <> " : " <> c_str <> " ;)"

        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == ast_str
      end
    end

    property "print statement" do
      check all {tokens, ast_str} <- expression() do
        tokens =
          [Token.new(:PRINT, "print", nil, 1) | tokens] ++
            [
              Token.new(:SEMICOLON, ";", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        p_str = "(print " <> ast_str <> " ;)"
        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == p_str
      end
    end

    property "variable declaration" do
      check all {id, _id_str} <- identifier(),
                {expr, expr_str} <- expression() do
        tokens =
          [
            Token.new(:VAR, "var", nil, 1),
            id,
            Token.new(:EQUAL, "=", nil, 1)
            | expr
          ] ++
            [
              Token.new(:SEMICOLON, ";", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        decl_str = "(var= #{id.lexeme} #{expr_str} ;)"

        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == decl_str
      end
    end

    property "variable declaration without an expression" do
      check all {id, _id_str} <- identifier() do
        tokens =
          [
            Token.new(:VAR, "var", nil, 1),
            id
          ] ++
            [
              Token.new(:SEMICOLON, ";", nil, 1),
              Token.new(:EOF, "", nil, 1)
            ]

        decl_str = "(var= #{id.lexeme} nil ;)"

        %Parser{program: [ast]} = Parser.new(tokens) |> Parser.parse()
        assert Statement.to_string(ast) == decl_str
      end
    end
  end
end
