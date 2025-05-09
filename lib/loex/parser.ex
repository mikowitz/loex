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
    {left, %__MODULE__{input: input} = parser} = comparison(parser)

    case input do
      [t | rest] when t.type in [:EQUAL_EQUAL, :BANG_EQUAL] ->
        {right, parser} = comparison(%__MODULE__{input: rest})
        {Binary.new(left, t.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp comparison(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: input} = parser} = term(parser)

    case input do
      [t | rest] when t.type in [:LESS, :LESS_EQUAL, :GREATER, :GREATER_EQUAL] ->
        {right, parser} = term(%__MODULE__{input: rest})
        {Binary.new(left, t.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp term(%__MODULE__{} = parser) do
    # {left, %__MODULE__{input: [token | rest]} = parser} = factor(parser)
    {left, %__MODULE__{input: input} = parser} = factor(parser)

    # case token.type do
    case input do
      [t | rest] when t.type in [:PLUS, :MINUS] ->
        {right, parser} = factor(%__MODULE__{input: rest})
        {Binary.new(left, t.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp factor(%__MODULE__{} = parser) do
    {left, %__MODULE__{input: input} = parser} = unary(parser)

    case input do
      [t | rest] when t.type in [:STAR, :SLASH] ->
        {right, parser} = unary(%__MODULE__{input: rest})
        {Binary.new(left, t.lexeme, right), parser}

      _ ->
        {left, parser}
    end
  end

  defp unary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      t when t in [:BANG, :MINUS] ->
        {expr, parser} = unary(%__MODULE__{parser | input: rest})
        {Unary.new(token.lexeme, expr, token.line), parser}

      _ ->
        primary(parser)
    end
  end

  defp primary(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      t when t in [:NUMBER, :STRING] ->
        {Primary.new(token.literal, token.line), %__MODULE__{parser | input: rest}}

      :NIL ->
        {Primary.new(nil, token.line), %__MODULE__{parser | input: rest}}

      :TRUE ->
        {Primary.new(true, token.line), %__MODULE__{parser | input: rest}}

      :FALSE ->
        {Primary.new(false, token.line), %__MODULE__{parser | input: rest}}

      :LEFT_PAREN ->
        {expr, %__MODULE__{input: [token | rest]} = parser} =
          expression(%__MODULE__{parser | input: rest})

        starting_line = token.line

        case token.type do
          :RIGHT_PAREN ->
            {Grouping.new(expr, starting_line), %__MODULE__{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expected `)', got `#{token.lexeme}'")
            {nil, parser |> with_errors() |> synchronize()}
        end

      _ ->
        Loex.error(token.line, "Unexpected token `#{token.lexeme}'")
        {nil, parser |> with_errors() |> synchronize()}
    end
  end

  defp with_errors(%__MODULE__{} = parser) do
    %__MODULE__{parser | has_errors: true}
  end

  defp synchronize(%__MODULE__{input: tokens} = parser) do
    case tokens do
      [] ->
        parser

      [token | rest] ->
        parser = %__MODULE__{parser | input: rest}

        case token.type do
          :SEMICOLON -> {nil, parser}
          _ -> synchronize(parser)
        end
    end
  end
end
