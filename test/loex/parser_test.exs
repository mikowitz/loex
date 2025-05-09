defmodule Loex.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import ExUnitProperties

  import LoexTest.Support.Generators

  alias Loex.Expr.{Binary, Grouping, Primary, Unary}
  alias Loex.{Parser, Scanner}

  describe "parsing a primary" do
    property "parsing a single primary literal" do
      check all input <- literal_expr() do
        input_str = if is_nil(input), do: "nil", else: to_string(input)

        %Scanner{tokens: tokens} = input_str |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == Primary.new(input, 1)
      end
    end

    property "parsing a grouping" do
      check all input <- literal_expr() do
        input_str = if is_nil(input), do: "(nil)", else: "(#{to_string(input)})"

        %Scanner{tokens: tokens} = input_str |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == Grouping.new(Primary.new(input, 1), 1)
      end
    end

    test "improper grouping" do
      %Scanner{tokens: tokens} = "(true" |> Scanner.new() |> Scanner.scan()

      assert capture_io(:stderr, fn ->
               Parser.new(tokens) |> Parser.parse()
             end) == "[line 1] Error: Expected `)', got `'\n"
    end

    property "unary expressions" do
      check all {input, expected} <- unary_expr() do
        %Scanner{tokens: tokens} = input |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == expected
      end
    end

    property "factor expressions" do
      check all {input, expected} <- factor_expr() do
        %Scanner{tokens: tokens} = input |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == expected
      end
    end

    property "term expressions" do
      check all {input, expected} <- term_expr() do
        %Scanner{tokens: tokens} = input |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == expected
      end
    end

    property "comparison expressions" do
      check all {input, expected} <- comparison_expr() do
        %Scanner{tokens: tokens} = input |> Scanner.new() |> Scanner.scan()
        %Parser{ast: ast} = Parser.new(tokens) |> Parser.parse()

        assert ast == expected
      end
    end
  end

  def unary_expr do
    gen all literal <- literal_expr(),
            unary <- unary(),
            should_group <- StreamData.boolean() do
      input_str = if is_nil(literal), do: "nil", else: to_string(literal)
      input_str = if should_group, do: "(#{input_str})", else: input_str
      input_str = unary <> input_str

      expr = Primary.new(literal, 1)
      expr = if should_group, do: Grouping.new(expr, 1), else: expr

      {input_str, Unary.new(unary, expr, 1)}
    end
  end

  def factor_expr do
    gen all {left, left_expr} <- unary_expr(),
            op <- factor(),
            {right, right_expr} <- unary_expr() do
      {
        left <> " " <> op <> " " <> right,
        Binary.new(left_expr, op, right_expr)
      }
    end
  end

  def term_expr do
    gen all {left, left_expr} <- factor_expr(),
            op <- term(),
            {right, right_expr} <- factor_expr() do
      {
        left <> " " <> op <> " " <> right,
        Binary.new(left_expr, op, right_expr)
      }
    end
  end

  def comparison_expr do
    gen all {left, left_expr} <- term_expr(),
            op <- comparison(),
            {right, right_expr} <- term_expr() do
      {
        left <> " " <> op <> " " <> right,
        Binary.new(left_expr, op, right_expr)
      }
    end
  end

  def equality_expr do
    gen all {left, left_expr} <- comparison_expr(),
            op <- comparison(),
            {right, right_expr} <- comparison_expr() do
      {
        left <> " " <> op <> " " <> right,
        Binary.new(left_expr, op, right_expr)
      }
    end
  end
end
