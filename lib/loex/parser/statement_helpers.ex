defmodule Loex.Parser.StatementHelpers do
  @moduledoc false

  alias Loex.Parser
  alias Loex.Token
  alias Loex.Statement.{Block, Expression, If, Print, While}

  def if_statement(parser) do
    case parser.input do
      [%Token{type: :LEFT_PAREN} | rest] ->
        {condition, parser} = Parser.expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :RIGHT_PAREN} | rest] ->
            {then_branch, parser} = Parser.statement(%{parser | input: rest})

            check_for_else(parser, condition, then_branch)

          [t | _] ->
            Loex.error(t.line, "Expect `)' after if condition")
            {nil, parser |> Parser.synchronize()}
        end

      [t | _] ->
        Loex.error(t.line, "Expect `(' after `if'")
        {nil, parser |> Parser.synchronize()}
    end
  end

  defp check_for_else(parser, condition, then_branch) do
    case parser.input do
      [%Token{type: :ELSE} | rest] ->
        {else_branch, parser} = Parser.statement(%{parser | input: rest})
        {If.new(condition, then_branch, else_branch), parser}

      _ ->
        {If.new(condition, then_branch, nil), parser}
    end
  end

  def print_statement(parser) do
    {expr, parser} = Parser.expression(parser)

    case parser.input do
      [%Token{type: :SEMICOLON} | rest] ->
        {
          Print.new(expr),
          %{parser | input: rest}
        }

      [t | _] ->
        Loex.error(t.line, "Expect `;' after value")
        {nil, parser}
    end
  end

  def block_statement(parser) do
    {stmt, parser} = Parser.declaration(parser)

    block_loop(parser, [stmt])
  end

  defp block_loop(parser, acc) do
    case parser.input do
      [%Token{type: :RIGHT_BRACE} | rest] ->
        {
          Block.new(Enum.reverse(acc)),
          %{parser | input: rest}
        }

      _ ->
        {stmt, parser} = Parser.declaration(parser)
        block_loop(parser, [stmt | acc])
    end
  end

  def expression_statement(parser) do
    {expr, parser} = Parser.expression(parser)

    case parser.input do
      [%Token{type: :SEMICOLON} | rest] ->
        {
          Expression.new(expr),
          %{parser | input: rest}
        }

      [t | _] ->
        Loex.error(t.line, "Expect `;' after value")
        {nil, parser}
    end
  end

  def while_statement(parser) do
    case parser.input do
      [%Token{type: :LEFT_PAREN} | rest] ->
        {condition, parser} = Parser.expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :RIGHT_PAREN} | rest] ->
            {body, parser} = Parser.statement(%{parser | input: rest})
            {While.new(condition, body), parser}

          [t | _rest] ->
            Loex.error(t.line, "Expect `)' after while condition")
            {nil, parser |> Parser.synchronize()}
        end

      [t | _rest] ->
        Loex.error(t.line, "Expect `(' after `while'.")
        {nil, parser |> Parser.synchronize()}
    end
  end
end
