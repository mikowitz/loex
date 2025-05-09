defmodule Loex.Parser do
  @moduledoc """
  Parser for the Lox language.

  Takes as input a list of Lox tokens and returns an AST.
  """
  alias Loex.Expr.{Binary, Grouping, Primary, Unary}

  defstruct [:input, :ast, has_errors: false]

  def new(input), do: %__MODULE__{input: input}

  def parse(%__MODULE__{} = parser) do
    {expr, parser} = expression(parser)
    %__MODULE__{parser | ast: expr}
  end

  def expression(%__MODULE__{} = parser) do
    equality(parser)
  end

  defp equality(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: [token | rest]} = parser} = comparison(parser)

    case token.type do
      t when t in [:EQUAL_EQUAL, :BANG_EQUAL] ->
        {right, parser} = comparison(%__MODULE__{input: rest})
        {Binary.new(left, token.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp comparison(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: [token | rest]} = parser} = term(parser)

    case token.type do
      t when t in [:LESS, :LESS_EQUAL, :GREATER, :GREATER_EQUAL] ->
        {right, parser} = term(%__MODULE__{input: rest})
        {Binary.new(left, token.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp term(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: [token | rest]} = parser} = factor(parser)

    case token.type do
      t when t in [:PLUS, :MINUS] ->
        {right, parser} = factor(%__MODULE__{input: rest})
        {Binary.new(left, token.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp factor(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: [token | rest]} = parser} = unary(parser)

    case token.type do
      t when t in [:STAR, :SLASH] ->
        {right, parser} = unary(%__MODULE__{input: rest})
        {Binary.new(left, token.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp unary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      t when t in [:BANG, :MINUS] ->
        {expr, parser} = unary(%__MODULE__{parser | input: rest})
        {Unary.new(token.lexeme, expr), parser}

      _ ->
        primary(parser)
    end
  end

  defp primary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      t when t in [:NUMBER, :STRING] ->
        {Primary.new(token.literal), %__MODULE__{parser | input: rest}}

      :NIL ->
        {Primary.new(nil), %__MODULE__{parser | input: rest}}

      :TRUE ->
        {Primary.new(true), %__MODULE__{parser | input: rest}}

      :FALSE ->
        {Primary.new(false), %__MODULE__{parser | input: rest}}

      :LEFT_PAREN ->
        {expr, %__MODULE__{input: [token | rest]} = parser} =
          expression(%__MODULE__{parser | input: rest})

        case token.type do
          :RIGHT_PAREN ->
            {Grouping.new(expr), %__MODULE__{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expected `)', got `#{token.lexeme}'")
            {nil, %{parser | has_errors: true}}
        end

      _ ->
        Loex.error(token.line, "Unexpected token `#{token.lexeme}'")
        {nil, %{parser | has_errors: true}}
    end
  end
end
