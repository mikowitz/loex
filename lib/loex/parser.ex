defmodule Loex.Parser do
  @moduledoc """
  Parses a series of [Loex.Tokens] into an AST expression.
  """

  defstruct [:tokens, :runtime, statements: []]

  alias Loex.Expr.{Binary, Grouping, Literal, Unary, Variable}
  alias Loex.Parser.Statements
  alias Loex.Stmt.Var

  def new(tokens, runtime \\ %Loex{}) do
    %__MODULE__{tokens: tokens, runtime: runtime}
  end

  def parse(%__MODULE__{tokens: []} = parser) do
    %{parser | statements: Enum.reverse(parser.statements)}
  end

  def parse(%__MODULE__{tokens: [%{type: :EOF}]} = parser) do
    %{parser | statements: Enum.reverse(parser.statements)}
  end

  def parse(%__MODULE__{} = parser) do
    {stmt, parser} = declaration(parser)

    case stmt do
      nil -> parser |> synchronize() |> parse()
      _ -> %{parser | statements: [stmt | parser.statements]} |> parse()
    end
  end

  def declaration(%__MODULE__{tokens: [%{type: :VAR} | rest]} = parser) do
    var_declaration(%{parser | tokens: rest})
  end

  def declaration(%__MODULE__{} = parser) do
    statement(parser)
  end

  def var_declaration(%__MODULE__{tokens: [%{type: :IDENTIFIER} = name | rest]} = parser) do
    {initializer, parser} =
      case rest do
        [%{type: :EQUAL} | rest] ->
          expression(%{parser | tokens: rest})

        _ ->
          {nil, parser}
      end

    case parser.tokens do
      [%{type: :SEMICOLON} | rest] ->
        {Var.new(name, initializer), %{parser | tokens: rest}}

      [t | _] ->
        runtime = Loex.error(parser.runtime, t, "Expect `;` after variable declaration.")
        {nil, %{parser | runtime: runtime}}
    end
  end

  def var_declaration(%__MODULE__{tokens: [t | _]} = parser) do
    runtime = Loex.error(parser.runtime, t, "Expect variable name.")
    {nil, %{parser | runtime: runtime}}
  end

  def statement(%__MODULE__{tokens: [%{type: :PRINT} | rest]} = parser) do
    Statements.print_statement(%{parser | tokens: rest})
  end

  def statement(%__MODULE__{} = parser) do
    Statements.expression_statement(parser)
  end

  def expression(%__MODULE__{} = parser), do: equality(parser)

  def equality(%__MODULE__{} = parser) do
    {expr, parser} = comparison(parser)

    do_equality(parser, expr)
  end

  defp do_equality(%__MODULE__{tokens: [n | rest]} = parser, expr)
       when n.type in [:BANG_EQUAL, :EQUAL_EQUAL] do
    operator = n
    {right, parser} = comparison(%{parser | tokens: rest})
    expr = Binary.new(expr, operator, right)
    do_equality(parser, expr)
  end

  defp do_equality(%__MODULE__{} = parser, expr) do
    {expr, parser}
  end

  def comparison(%__MODULE__{} = parser) do
    {expr, parser} = term(parser)
    do_comparison(parser, expr)
  end

  defp do_comparison(%__MODULE__{tokens: [n | rest]} = parser, expr)
       when n.type in [:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL] do
    operator = n
    {right, parser} = term(%{parser | tokens: rest})
    expr = Binary.new(expr, operator, right)
    do_comparison(parser, expr)
  end

  defp do_comparison(%__MODULE__{} = parser, expr) do
    {expr, parser}
  end

  def term(%__MODULE__{} = parser) do
    {expr, parser} = factor(parser)
    do_term(parser, expr)
  end

  defp do_term(%__MODULE__{tokens: [n | rest]} = parser, expr)
       when n.type in [:MINUS, :PLUS] do
    operator = n
    {right, parser} = factor(%{parser | tokens: rest})
    expr = Binary.new(expr, operator, right)
    do_term(parser, expr)
  end

  defp do_term(%__MODULE__{} = parser, expr) do
    {expr, parser}
  end

  def factor(%__MODULE__{} = parser) do
    {expr, parser} = unary(parser)
    do_factor(parser, expr)
  end

  defp do_factor(%__MODULE__{tokens: [n | rest]} = parser, expr)
       when n.type in [:STAR, :SLASH] do
    operator = n
    {right, parser} = unary(%{parser | tokens: rest})
    expr = Binary.new(expr, operator, right)
    do_factor(parser, expr)
  end

  defp do_factor(%__MODULE__{} = parser, expr) do
    {expr, parser}
  end

  def unary(%__MODULE__{tokens: [n | rest]} = parser)
      when n.type in [:BANG, :MINUS] do
    {right, parser} = unary(%{parser | tokens: rest})
    {Unary.new(n, right), parser}
  end

  def unary(%__MODULE__{} = parser), do: primary(parser)

  def primary(%__MODULE__{tokens: [%{type: :FALSE} | rest]} = parser) do
    {Literal.new(false), %{parser | tokens: rest}}
  end

  def primary(%__MODULE__{tokens: [%{type: :TRUE} | rest]} = parser) do
    {Literal.new(true), %{parser | tokens: rest}}
  end

  def primary(%__MODULE__{tokens: [%{type: :NIL} | rest]} = parser) do
    {Literal.new(nil), %{parser | tokens: rest}}
  end

  def primary(%__MODULE__{tokens: [%{type: :IDENTIFIER} = t | rest]} = parser) do
    {Variable.new(t), %{parser | tokens: rest}}
  end

  def primary(%__MODULE__{tokens: [n | rest]} = parser) when n.type in [:NUMBER, :STRING] do
    {Literal.new(n.literal), %{parser | tokens: rest}}
  end

  def primary(%__MODULE__{tokens: [n | rest]} = parser) when n.type == :LEFT_PAREN do
    {expr, parser} = expression(%{parser | tokens: rest})

    case parser.tokens do
      [%{type: :RIGHT_PAREN} | rest] ->
        {Grouping.new(expr), %{parser | tokens: rest}}

      [t | _] ->
        runtime = Loex.error(parser.runtime, t, "Expect `)` after expression.")
        {nil, %{parser | runtime: runtime}}
    end
  end

  def primary(%__MODULE__{tokens: [t | _rest]} = parser) do
    Loex.error(parser.runtime, t, "Expect expression.")
    {nil, parser}
  end

  defp synchronize(%__MODULE__{tokens: []} = parser), do: parser

  defp synchronize(%__MODULE__{tokens: [t | rest]} = parser) do
    cond do
      t.type == :SEMICOLON ->
        %{parser | tokens: rest}

      :otherwise ->
        case rest do
          [%{type: tt} | _] when tt in ~w(CLASS FUN VAR FOR IF WHILE PRINT RETURN)a ->
            parser

          _ ->
            %{parser | tokens: rest}
        end
    end
  end
end
