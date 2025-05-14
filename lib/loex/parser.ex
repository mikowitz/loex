defmodule Loex.Parser do
  @moduledoc """
  Handles parsing a list of Lox tokens into an AST.
  """

  alias Loex.Expr.{Grouping, Literal, Unary}
  alias Loex.Token

  defstruct [:input, :ast, has_errors: false]

  def new(input), do: %__MODULE__{input: input}

  def parse(%__MODULE__{} = parser) do
    {ast, parser} = expression(parser)
    %__MODULE__{parser | ast: ast}
  end

  def expression(%__MODULE__{} = parser), do: unary(parser)

  defp unary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      t when t in [:BANG, :MINUS] ->
        {expr, parser} = unary(%{parser | input: rest})
        {Unary.new(token.lexeme, expr), parser}

      _ ->
        primary(parser)
    end
  end

  defp primary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      :FALSE ->
        {Literal.new(false), %{parser | input: rest}}

      :TRUE ->
        {Literal.new(true), %{parser | input: rest}}

      :NIL ->
        {Literal.new(nil), %{parser | input: rest}}

      :STRING ->
        {Literal.new(token.literal), %{parser | input: rest}}

      :NUMBER ->
        {Literal.new(token.literal), %{parser | input: rest}}

      :LEFT_PAREN ->
        {expr, %{input: input} = parser} = expression(%{parser | input: rest})

        case input do
          [%Token{type: :RIGHT_PAREN} | rest] ->
            {Grouping.new(expr), %{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expect `)' after expression.")
            {nil, parser}
        end
    end
  end
end
