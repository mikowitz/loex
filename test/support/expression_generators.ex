defmodule Loex.Test.Support.ExpressionGenerators do
  @moduledoc false

  use ExUnitProperties

  alias Loex.Token

  def primary_expr do
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

  def grouping_expr do
    primary_expr()
    |> map(fn {token, str} ->
      {
        [Token.new(:LEFT_PAREN, "(", nil, 1), token, Token.new(:RIGHT_PAREN, ")", nil, 1)],
        "(group #{str})"
      }
    end)
  end

  def unary_expr do
    gen all {expr, expr_str} <- grouping_expr(),
            {op_token, op_str} <- unary_operator() do
      {[op_token | expr], "(#{op_str} #{expr_str})"}
    end
  end

  def factor_expr do
    gen all {left, left_str} <- one_of([primary_expr(), grouping_expr(), unary_expr()]),
            {right, right_str} <- one_of([primary_expr(), grouping_expr(), unary_expr()]),
            {op_token, op_str} <- factor_operator() do
      {
        List.wrap(left) ++ [op_token | List.wrap(right)],
        "(#{op_str} #{left_str} #{right_str})"
      }
    end
  end

  def term_expr do
    gen all {left, left_str} <-
              one_of([primary_expr(), grouping_expr(), unary_expr(), factor_expr()]),
            {right, right_str} <-
              one_of([primary_expr(), grouping_expr(), unary_expr(), factor_expr()]),
            {op_token, op_str} <- term_operator() do
      {
        List.wrap(left) ++ [op_token | List.wrap(right)],
        "(#{op_str} #{left_str} #{right_str})"
      }
    end
  end

  defp unary_operator do
    one_of([
      constant({Token.new(:BANG, "!", nil, 1), "!"}),
      constant({Token.new(:MINUS, "-", nil, 1), "-"})
    ])
  end

  defp factor_operator do
    one_of([
      constant({Token.new(:STAR, "*", nil, 1), "*"}),
      constant({Token.new(:SLASH, "/", nil, 1), "/"})
    ])
  end

  defp term_operator do
    one_of([
      constant({Token.new(:PLUS, "+", nil, 1), "+"}),
      constant({Token.new(:MINUS, "-", nil, 1), "-"})
    ])
  end
end
