defmodule Loex.ParserTest do
  use ExUnit.Case, async: true

  alias Loex.Expr.{Binary, Grouping, Literal, Unary}
  alias Loex.Parser
  alias Loex.Scanner
  alias Loex.Token

  describe "parse" do
    test "binary" do
      source = "3 <= 4"
      scanner = Scanner.new(source) |> Scanner.scan()
      {expr, parser} = Parser.new(scanner.tokens) |> Parser.parse()

      %Binary{
        left: %Literal{value: 3.0},
        operator: %Token{type: :LESS_EQUAL},
        right: %Literal{value: 4.0}
      } = expr

      refute parser.runtime.had_error
    end

    test "unary" do
      source = "!3"
      scanner = Scanner.new(source) |> Scanner.scan()
      {expr, parser} = Parser.new(scanner.tokens) |> Parser.parse()

      %Unary{
        operator: %Token{type: :BANG},
        right: %Literal{value: 3.0}
      } = expr

      refute parser.runtime.had_error
    end

    test "grouping" do
      source = "(3 + 4)"
      scanner = Scanner.new(source) |> Scanner.scan()
      {expr, parser} = Parser.new(scanner.tokens) |> Parser.parse()

      %Grouping{
        expression: %Binary{
          left: %Literal{value: 3.0},
          operator: %Token{type: :PLUS},
          right: %Literal{value: 4.0}
        }
      } = expr

      refute parser.runtime.had_error
    end
  end
end
