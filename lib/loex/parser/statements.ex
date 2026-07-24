defmodule Loex.Parser.Statements do
  @moduledoc false

  alias Loex.Parser
  alias Loex.Stmt.{Expression, Print}

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
