defmodule Loex.Parser do
  @moduledoc """
  Handles parsing a list of Lox tokens into an AST.
  """

  alias Loex.Expr.{Binary, Grouping, Literal, Unary}
  alias Loex.Token

  defstruct [:input, :ast, has_errors: false]

  def new(input), do: %__MODULE__{input: input}

  def parse(%__MODULE__{} = parser) do
    {ast, parser} = expression(parser)
    %__MODULE__{parser | ast: ast}
  end

  def expression(%__MODULE__{} = parser), do: equality(parser)

  defp equality(%__MODULE__{} = parser) do
    {expr, parser} = comparison(parser)

    equality_loop(expr, parser)
  end

  def equality_loop(expr, %__MODULE__{} = parser) do
    case parser.input do
      [%Token{type: t} = token | rest] when t in [:EQUAL_EQUAL, :BANG_EQUAL] ->
        {right, parser} = comparison(%{parser | input: rest})
        expr = Binary.new(expr, token.lexeme, right)
        equality_loop(expr, parser)

      _ ->
        {expr, parser}
    end
  end

  defp comparison(%__MODULE__{} = parser) do
    {expr, parser} = term(parser)

    comparison_loop(expr, parser)
  end

  def comparison_loop(expr, %__MODULE__{} = parser) do
    case parser.input do
      [%Token{type: t} = token | rest] when t in [:GREATER, :LESS, :GREATER_EQUAL, :LESS_EQUAL] ->
        {right, parser} = term(%{parser | input: rest})
        expr = Binary.new(expr, token.lexeme, right)
        comparison_loop(expr, parser)

      _ ->
        {expr, parser}
    end
  end

  defp term(%__MODULE__{} = parser) do
    {expr, parser} = factor(parser)

    term_loop(expr, parser)
  end

  def term_loop(expr, %__MODULE__{} = parser) do
    case parser.input do
      [%Token{type: t} = token | rest] when t in [:PLUS, :MINUS] ->
        {right, parser} = factor(%{parser | input: rest})
        expr = Binary.new(expr, token.lexeme, right)
        term_loop(expr, parser)

      _ ->
        {expr, parser}
    end
  end

  defp factor(%__MODULE__{} = parser) do
    {expr, parser} = unary(parser)

    factor_loop(expr, parser)
  end

  def factor_loop(expr, %__MODULE__{} = parser) do
    case parser.input do
      [%Token{type: t} = token | rest] when t in [:SLASH, :STAR] ->
        {right, parser} = unary(%{parser | input: rest})
        expr = Binary.new(expr, token.lexeme, right)
        factor_loop(expr, parser)

      _ ->
        {expr, parser}
    end
  end

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
