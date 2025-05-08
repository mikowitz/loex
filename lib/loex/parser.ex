defmodule Loex.Parser do
  @moduledoc """
  Parser for the Lox language.

  Takes as input a list of Lox tokens and returns an AST.
  """
  alias Loex.Expr.Unary
  alias Loex.Expr.{Grouping, Primary}

  defstruct [:input, :ast, has_errors: false]

  def new(input), do: %__MODULE__{input: input}

  def parse(%__MODULE__{} = parser) do
    {expr, parser} = unary(parser)
    %__MODULE__{parser | ast: expr}
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
          primary(%__MODULE__{parser | input: rest})

        case token.type do
          :RIGHT_PAREN ->
            {Grouping.new(expr), %__MODULE__{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expected `)', got `#{token.lexeme}'")
            {nil, parser}
        end

      _ ->
        Loex.error(token.line, "Expected expression at #{token.lexeme}")
        {nil, %{parser | has_errors: true}}
    end
  end
end
