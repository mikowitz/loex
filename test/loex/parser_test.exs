defmodule Loex.ParserTest do
  use ExUnit.Case, async: true

  alias Loex.Expr.{Binary, Grouping, Literal, Unary}
  alias Loex.Parser
  alias Loex.Scanner
  alias Loex.Stmt.{Expression, Print}
  alias Loex.Token

  describe "parse" do
    test "binary" do
      source = "3 <= 4;"
      scanner = Scanner.new(source) |> Scanner.scan()
      parser = Parser.new(scanner.tokens) |> Parser.parse()

      [
        %Expression{
          expression: %Binary{
            left: %Literal{value: 3.0},
            operator: %Token{type: :LESS_EQUAL},
            right: %Literal{value: 4.0}
          }
        }
      ] = parser.statements

      refute parser.runtime.had_error
    end

    test "unary" do
      source = "!3;"
      scanner = Scanner.new(source) |> Scanner.scan()
      parser = Parser.new(scanner.tokens) |> Parser.parse()

      [
        %Expression{
          expression: %Unary{
            operator: %Token{type: :BANG},
            right: %Literal{value: 3.0}
          }
        }
      ] = parser.statements

      refute parser.runtime.had_error
    end

    test "grouping" do
      source = "print (3 + 4);"
      scanner = Scanner.new(source) |> Scanner.scan()
      parser = Parser.new(scanner.tokens) |> Parser.parse()

      [
        %Print{
          expression: %Grouping{
            expression: %Binary{
              left: %Literal{value: 3.0},
              operator: %Token{type: :PLUS},
              right: %Literal{value: 4.0}
            }
          }
        }
      ] = parser.statements

      refute parser.runtime.had_error
    end
  end
end
