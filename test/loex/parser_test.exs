defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import ExUnitProperties

  import LoexTest.Support.Generators

  alias Loex.Expr.{Grouping, Primary, Unary}
  alias Loex.Parser
  alias Loex.Scanner

  describe "parsing a primary" do
    property "parsing a single primary literal" do
      check all input <- literal_expr() do
        input_str = if is_nil(input), do: "nil", else: to_string(input)

        %Scanner{tokens: tokens} = input_str |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == %Primary{literal: input}
      end
    end

    property "parsing a grouping" do
      check all input <- literal_expr() do
        input_str = if is_nil(input), do: "(nil)", else: "(#{to_string(input)})"

        %Scanner{tokens: tokens} = input_str |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == %Grouping{expr: %Primary{literal: input}}
      end
    end

    test "improper grouping" do
      %Scanner{tokens: tokens} = "(true+" |> Scanner.new() |> Scanner.scan()

      assert capture_io(:stderr, fn ->
               Parser.new(tokens) |> Parser.parse()
             end) == "[line 1] Error: Expected `)', got `+'\n"
    end

    property "unary expressions" do
      check all literal <- literal_expr(),
                unary <- unary(),
                should_group <- StreamData.boolean() do
        input_str = if is_nil(literal), do: "nil", else: to_string(literal)
        input_str = if should_group, do: "(#{input_str})", else: input_str
        input_str = unary <> input_str

        %Scanner{tokens: tokens} = input_str |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        if should_group do
          assert ast == %Unary{operator: unary, expr: %Grouping{expr: %Primary{literal: literal}}}
        else
          assert ast == %Unary{operator: unary, expr: %Primary{literal: literal}}
        end
      end
    end
  end
end
