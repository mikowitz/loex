defmodule Loex.Parser do
  @moduledoc """
  Handles parsing a list of Lox tokens into an AST.
  """

  alias Loex.Statement.While

  alias Loex.Expr.{
    Assign,
    Binary,
    CommaSeries,
    Grouping,
    Literal,
    Logical,
    Ternary,
    Unary,
    Variable
  }

  alias Loex.Statement
  alias Loex.Statement.Block
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
    {ast, parser} = declaration(parser)

    case ast do
      nil -> parser |> synchronize() |> parse()
      _ -> %__MODULE__{parser | program: [ast | program]} |> parse()
    end
  end

  def declaration(%{input: [%Token{type: :VAR} | rest]} = parser) do
    variable_declaration(%{parser | input: rest})
  end

  def declaration(parser) do
    statement(parser)
  end

  def variable_declaration(%{input: tokens} = parser) do
    case tokens do
      [%Token{type: :IDENTIFIER} = token, %Token{type: :EQUAL} | rest] ->
        {expr, parser} = expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :SEMICOLON} | rest] ->
            {Statement.VariableDeclaration.new(token.lexeme, expr), %{parser | input: rest}}

          _ ->
            Loex.error(token.line, "Expect `;' after value")
            {nil, parser |> synchronize()}
        end

      [%Token{type: :IDENTIFIER} = token, %Token{type: :SEMICOLON} | rest] ->
        {Statement.VariableDeclaration.new(token.lexeme, Literal.new(nil)),
         %{parser | input: rest}}

      [%Token{type: :IDENTIFIER} = token | _] ->
        Loex.error(token.line, "Expect `;' or expression after variable declaration")
        {nil, parser |> synchronize()}

      [t | _] ->
        Loex.error(t.line, "Expect variable name after `var'")
        {nil, parser |> synchronize()}
    end
  end

  def statement(%{input: [%Token{type: :PRINT} | rest]} = parser) do
    print_statement(%{parser | input: rest})
  end

  def statement(%{input: [%Token{type: :LEFT_BRACE} | rest]} = parser) do
    block_statement(%{parser | input: rest})
  end

  def statement(%{input: [%Token{type: :WHILE} | rest]} = parser) do
    case rest do
      [%Token{type: :LEFT_PAREN} | rest] ->
        {condition, parser} = expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :RIGHT_PAREN} | rest] ->
            {body, parser} = statement(%{parser | input: rest})
            {While.new(condition, body), parser}

          [t | _rest] ->
            Loex.error(t.line, "Expect `)' after while condition")
            {nil, parser |> synchronize()}
        end

      [t | _rest] ->
        Loex.error(t.line, "Expect `(' after `while'.")
        {nil, parser |> synchronize()}
    end
  end

  def statement(%{input: [%Token{type: :IF} | rest]} = parser) do
    if_statement(%{parser | input: rest})
  end

  def statement(parser) do
    expression_statement(parser)
  end

  defp if_statement(parser) do
    case parser.input do
      [%Token{type: :LEFT_PAREN} | rest] ->
        {condition, parser} = expression(%{parser | input: rest})

        case parser.input do
          [%Token{type: :RIGHT_PAREN} | rest] ->
            {then_branch, parser} = statement(%{parser | input: rest})

            check_for_else(parser, condition, then_branch)

          [t | _] ->
            Loex.error(t.line, "Expect `)' after if condition")
            {nil, parser |> synchronize()}
        end

      [t | _] ->
        Loex.error(t.line, "Expect `(' after `if'")
        {nil, parser |> synchronize()}
    end
  end

  defp check_for_else(parser, condition, then_branch) do
    case parser.input do
      [%Token{type: :ELSE} | rest] ->
        {else_branch, parser} = statement(%{parser | input: rest})
        {Statement.If.new(condition, then_branch, else_branch), parser}

      _ ->
        {Statement.If.new(condition, then_branch, nil), parser}
    end
  end

  defp print_statement(parser) do
    {expr, parser} = expression(parser)

    case parser.input do
      [%Token{type: :SEMICOLON} | rest] ->
        {
          Statement.Print.new(expr),
          %{parser | input: rest}
        }

      [t | _] ->
        Loex.error(t.line, "Expect `;' after value")
        {nil, parser}
    end
  end

  defp block_statement(parser) do
    {stmt, parser} = declaration(parser)

    block_loop(parser, [stmt])
  end

  defp block_loop(parser, acc) do
    case parser.input do
      [%Token{type: :RIGHT_BRACE} | rest] ->
        {
          Block.new(Enum.reverse(acc)),
          %{parser | input: rest}
        }

      _ ->
        {stmt, parser} = declaration(parser)
        block_loop(parser, [stmt | acc])
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

      [t | _] ->
        Loex.error(t.line, "Expect `;' after value")
        {nil, parser}
    end
  end

  def expression(%__MODULE__{} = parser), do: assignment(parser)

  def assignment(%__MODULE__{} = parser) do
    {expr, parser} = or_expr(parser)

    case parser.input do
      [%Token{type: :EQUAL, line: line} | rest] ->
        {value, parser} = assignment(%{parser | input: rest})

        case expr do
          %Variable{} ->
            {Assign.new(expr, value), parser}

          _ ->
            Loex.error(line, "Invalid assignment target")
            {nil, parser |> synchronize()}
        end

      _ ->
        {expr, parser}
    end
  end

  def or_expr(parser) do
    {expr, parser} = and_expr(parser)
    or_expr_loop(parser, expr)
  end

  defp or_expr_loop(parser, expr) do
    case parser.input do
      [%Token{type: :OR} = token | rest] ->
        {right, parser} = and_expr(%{parser | input: rest})

        expr = Logical.new(expr, token, right)
        or_expr_loop(parser, expr)

      _ ->
        {expr, parser}
    end
  end

  def and_expr(parser) do
    {expr, parser} = comma_series(parser)

    and_expr_loop(parser, expr)
  end

  defp and_expr_loop(parser, expr) do
    case parser.input do
      [%Token{type: :AND} = token | rest] ->
        {right, parser} = comma_series(%{parser | input: rest})

        expr = Logical.new(expr, token, right)
        and_expr_loop(parser, expr)

      _ ->
        {expr, parser}
    end
  end

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

          [t | _rest] ->
            Loex.error(t.line, "Expected `:' in ternary expression")
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
        {Unary.new(token, expr), parser}

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

  defp primary(%__MODULE__{input: [%Token{type: :IDENTIFIER} = token | rest]} = parser),
    do: {Variable.new(token.lexeme, token.line), %{parser | input: rest}}

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
      [] ->
        parser

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
