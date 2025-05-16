defmodule Loex.Parser do
  @moduledoc """
  Handles parsing a list of Lox tokens into an AST.
  """

  alias Loex.Statement
  alias Loex.Expr.{Binary, CommaSeries, Grouping, Literal, Ternary, Unary}
  alias Loex.Token

  defstruct [:input, program: [], has_errors: false]

  def new(input), do: %__MODULE__{input: input}

  def parse(%__MODULE__{input: [%Token{type: :EOF}], program: program} = parser) do
    %{parser | program: Enum.reverse(program)}
  end

  def parse(%__MODULE__{input: [], program: program} = parser) do
    %{parser | program: Enum.reverse(program)}
  end

  def parse(%__MODULE__{program: program} = parser) do
    {ast, parser} = statement(parser)
    %__MODULE__{parser | program: [ast | program]} |> parse()
  end

  def statement(%{input: [%Token{type: :PRINT} | rest]} = parser) do
    print_statement(%{parser | input: rest})
  end

  def statement(parser) do
    expression_statement(parser)
  end

  defp print_statement(parser) do
    {expr, parser} = expression(parser)

    case parser.input do
      [%Token{type: :SEMICOLON} | rest] ->
        {
          Statement.Print.new(expr),
          %{parser | input: rest}
        }

      _ ->
        raise "Expect `;' after value"
    end
  end

  def expression_statement(parser) do
    {expr, parser} = expression(parser)

    case parser.input do
      [%Token{type: :SEMICOLON} | rest] ->
        {
          Statement.Expression.new(expr),
          %{parser | input: rest}
        }

      _ ->
        raise "Expect `;' after value"
    end
  end

  def expression(%__MODULE__{} = parser), do: comma_series(parser)

  def comma_series(%__MODULE__{} = parser) do
    {expr, parser} = ternary(parser)

    comma_series_loop(expr, parser)
  end

  defp comma_series_loop(expr, parser) do
    case parser.input do
      [%Token{type: :COMMA} | rest] ->
        {right, parser} = ternary(%{parser | input: rest})
        expr = CommaSeries.new(expr, right)
        comma_series_loop(expr, parser)

      _ ->
        {expr, parser}
    end
  end

  def ternary(%__MODULE__{} = parser) do
    {condition, %__MODULE__{input: input} = parser} = equality(parser)

    case input do
      [t | rest] when t.type == :QUESTION_MARK ->
        {left, %__MODULE__{input: input} = parser} = ternary(%__MODULE__{input: rest})

        case input do
          [t | rest] when t.type == :COLON ->
            {right, parser} = ternary(%__MODULE__{input: rest})
            {Ternary.new(condition, left, right), parser}

          _ ->
            Loex.error(1, "Expected `:' in ternary expression")
            {nil, parser |> with_errors() |> synchronize()}
        end

      _ ->
        {condition, parser}
    end
  end

  defp equality(%__MODULE__{} = parser) do
    {expr, parser} = comparison(parser)

    equality_loop(expr, parser)
  end

  def equality_loop(expr, %__MODULE__{} = parser) do
    case parser.input do
      [%Token{type: t} = token | rest] when t in [:EQUAL_EQUAL, :BANG_EQUAL] ->
        {right, parser} = comparison(%{parser | input: rest})
        expr = Binary.new(expr, token, right)
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
        expr = Binary.new(expr, token, right)
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
        expr = Binary.new(expr, token, right)
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
        expr = Binary.new(expr, token, right)
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

  defp primary(%__MODULE__{input: [%Token{type: :FALSE} | rest]} = parser),
    do: {Literal.new(false), %{parser | input: rest}}

  defp primary(%__MODULE__{input: [%Token{type: :TRUE} | rest]} = parser),
    do: {Literal.new(true), %{parser | input: rest}}

  defp primary(%__MODULE__{input: [%Token{type: :NIL} | rest]} = parser),
    do: {Literal.new(nil), %{parser | input: rest}}

  defp primary(%__MODULE__{input: [%Token{type: :STRING} = token | rest]} = parser),
    do: {Literal.new(token.literal), %{parser | input: rest}}

  defp primary(%__MODULE__{input: [%Token{type: :NUMBER} = token | rest]} = parser),
    do: {Literal.new(token.literal), %{parser | input: rest}}

  defp primary(%__MODULE__{input: [%Token{type: :LEFT_PAREN} = token | rest]} = parser) do
    {expr, %{input: input} = parser} = expression(%{parser | input: rest})

    case input do
      [%Token{type: :RIGHT_PAREN} | rest] ->
        {Grouping.new(expr), %{parser | input: rest}}

      _ ->
        Loex.error(token.line, "Expect `)' after expression.")
        {nil, parser}
    end
  end

  defp primary(%__MODULE__{input: [%Token{type: :EOF} = token]} = parser) do
    Loex.error(token.line, "Unexpected EOF")
    {nil, parser |> with_errors()}
  end

  defp primary(%__MODULE__{input: [token | _]} = parser) do
    Loex.error(token.line, "Unexpected token `#{token.lexeme}'")
    {nil, parser |> with_errors() |> synchronize |> parse()}
  end

  defp with_errors(%__MODULE__{} = parser), do: %{parser | has_errors: true}

  defp synchronize(%__MODULE__{input: [token | rest]} = parser) do
    case token.type do
      :EOF ->
        parse(parser)

      :SEMICOLON ->
        %{parser | input: rest}

      t when t in [:CLASS, :FUN, :VAR, :FOR, :IF, :WHILE, :PRINT, :RETURN] ->
        parser

      _ ->
        %{parser | input: rest} |> synchronize()
    end
  end
end
