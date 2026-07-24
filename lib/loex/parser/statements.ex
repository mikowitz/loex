defmodule Loex.Parser.Statements do
  @moduledoc false

  alias Loex.Parser
  alias Loex.Stmt.{Block, Expression, Print}

  def block_statement(%Parser{} = parser) do
    statements = []
    block_loop(parser, statements)
  end

  defp block_loop(%Parser{tokens: [%{type: :RIGHT_BRACE} | rest]} = parser, statements) do
    {Block.new(Enum.reverse(statements)), %{parser | tokens: rest}}
  end

  defp block_loop(%Parser{} = parser, statements) do
    {decl, parser} = Parser.declaration(parser)
    block_loop(parser, [decl | statements])
  end

  def print_statement(%Parser{} = parser) do
    {value, parser} = Loex.Parser.expression(parser)

    case parser.tokens do
      [%{type: :SEMICOLON} | rest] ->
        {Print.new(value), %{parser | tokens: rest}}

      [t | _] ->
        runtime = Loex.error(parser.runtime, t, "Expect `;` after value.")
        {nil, %{parser | runtime: runtime}}
    end
  end

  def expression_statement(%Parser{} = parser) do
    {value, parser} = Loex.Parser.expression(parser)

    case parser.tokens do
      [%{type: :SEMICOLON} | rest] ->
        {Expression.new(value), %{parser | tokens: rest}}

      [t | _] ->
        runtime = Loex.error(parser.runtime, t, "Expect `;` after value.")
        {nil, %{parser | runtime: runtime}}
    end
  end
end
