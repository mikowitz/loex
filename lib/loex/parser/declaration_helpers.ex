defmodule Loex.Parser.DeclarationHelpers do
  @moduledoc false

  alias Loex.Expr.Literal
  alias Loex.Statement.VariableDeclaration
  alias Loex.Token

  def variable_declaration(%{input: tokens} = parser) do
    case tokens do
      [%Token{type: :IDENTIFIER} = token, %Token{type: :EQUAL} | rest] ->
        {expr, parser} = Loex.Parser.expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :SEMICOLON} | rest] ->
            {VariableDeclaration.new(token.lexeme, expr), %{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expect `;' after value")
            {nil, parser |> Loex.Parser.synchronize()}
        end

      [%Token{type: :IDENTIFIER} = token, %Token{type: :SEMICOLON} | rest] ->
        {VariableDeclaration.new(token.lexeme, Literal.new(nil)), %{parser | input: rest}}

      [%Token{type: :IDENTIFIER} = token | _] ->
        Loex.error(token.line, "Expect `;' or expression after variable declaration")
        {nil, parser |> Loex.Parser.synchronize()}

      [t | _] ->
        Loex.error(t.line, "Expect variable name after `var'")
        {nil, parser |> Loex.Parser.synchronize()}
    end
  end
end
