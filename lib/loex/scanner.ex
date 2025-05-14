defmodule Loex.Scanner do
  @moduledoc """
  Handles scanning Lox source code and converting it into a list of tokens.
  """
  alias Loex.Token
  defstruct [:input, tokens: [], current_line: 1, has_errors: false]

  defguardp is_alpha(a) when a in ?a..?z or a in ?A..?Z or a == ?_
  defguardp is_digit(d) when d in ?0..?9
  defguardp is_alphanum(a) when is_alpha(a) or is_digit(a)

  def new(input) do
    %__MODULE__{input: input}
  end

  def scan(%__MODULE__{input: "", tokens: tokens} = scanner) do
    tokens = [
      Token.new(:EOF, "", nil, scanner.current_line) | tokens
    ]

    %__MODULE__{scanner | tokens: Enum.reverse(tokens)}
  end

  def scan(%{input: "(" <> rest} = scanner), do: push_token(scanner, rest, :LEFT_PAREN, "(")
  def scan(%{input: ")" <> rest} = scanner), do: push_token(scanner, rest, :RIGHT_PAREN, ")")
  def scan(%{input: "{" <> rest} = scanner), do: push_token(scanner, rest, :LEFT_BRACE, "{")
  def scan(%{input: "}" <> rest} = scanner), do: push_token(scanner, rest, :RIGHT_BRACE, "}")
  def scan(%{input: "," <> rest} = scanner), do: push_token(scanner, rest, :COMMA, ",")
  def scan(%{input: "." <> rest} = scanner), do: push_token(scanner, rest, :DOT, ".")
  def scan(%{input: "-" <> rest} = scanner), do: push_token(scanner, rest, :MINUS, "-")
  def scan(%{input: "+" <> rest} = scanner), do: push_token(scanner, rest, :PLUS, "+")
  def scan(%{input: ";" <> rest} = scanner), do: push_token(scanner, rest, :SEMICOLON, ";")
  def scan(%{input: "*" <> rest} = scanner), do: push_token(scanner, rest, :STAR, "*")
  def scan(%{input: "!=" <> rest} = scanner), do: push_token(scanner, rest, :BANG_EQUAL, "!=")
  def scan(%{input: "!" <> rest} = scanner), do: push_token(scanner, rest, :BANG, "!")
  def scan(%{input: "==" <> rest} = scanner), do: push_token(scanner, rest, :EQUAL_EQUAL, "==")
  def scan(%{input: "=" <> rest} = scanner), do: push_token(scanner, rest, :EQUAL, "=")
  def scan(%{input: ">=" <> rest} = scanner), do: push_token(scanner, rest, :GREATER_EQUAL, ">=")
  def scan(%{input: ">" <> rest} = scanner), do: push_token(scanner, rest, :GREATER, ">")
  def scan(%{input: "<=" <> rest} = scanner), do: push_token(scanner, rest, :LESS_EQUAL, "<=")
  def scan(%{input: "<" <> rest} = scanner), do: push_token(scanner, rest, :LESS, "<")
  def scan(%{input: "//" <> _} = scanner), do: comment(scanner)
  def scan(%{input: "/*" <> _} = scanner), do: block_comment(scanner)
  def scan(%{input: "/" <> rest} = scanner), do: push_token(scanner, rest, :SLASH, "/")
  def scan(%{input: "\t" <> rest} = scanner), do: ignore_character(scanner, rest)
  def scan(%{input: " " <> rest} = scanner), do: ignore_character(scanner, rest)
  def scan(%{input: "\n" <> rest} = scanner), do: scanner |> add_line() |> ignore_character(rest)
  def scan(%{input: "\"" <> _} = scanner), do: string(scanner)
  def scan(%{input: <<d, _::binary>>} = scanner) when is_digit(d), do: number(scanner)
  def scan(%{input: <<a, _::binary>>} = scanner) when is_alpha(a), do: identifier(scanner)
  def scan(%__MODULE__{} = scanner), do: handle_unknown_character(scanner)

  defp ignore_character(scanner, rest) do
    scanner |> with_input(rest) |> scan()
  end

  defp push_token(scanner, rest, token_type, lexeme, literal \\ nil) do
    scanner |> with_input(rest) |> add_token(token_type, lexeme, literal) |> scan()
  end

  defp comment(%__MODULE__{input: input} = scanner) do
    case String.split(input, "\n", parts: 2) do
      [_rest] -> ignore_character(scanner, "")
      [_comment, rest] -> scanner |> add_line() |> ignore_character(rest)
    end
  end

  defp block_comment(%__MODULE__{input: input} = scanner) do
    case String.split(input, "*/", parts: 2) do
      [_rest] ->
        ignore_character(scanner, "")

      [comment, rest] ->
        line_delta = String.codepoints(comment) |> Enum.count(&(&1 == "\n"))
        scanner |> add_lines(line_delta) |> ignore_character(rest)
    end
  end

  defp string(%__MODULE__{input: "\"" <> input} = scanner) do
    case String.split(input, "\"", parts: 2) do
      [_rest] ->
        Loex.error(scanner.current_line, "Unterminated string")
        scanner |> with_errors() |> ignore_character("")

      [string, rest] ->
        line_delta = String.codepoints(string) |> Enum.count(&(&1 == "\n"))

        scanner
        |> with_input(rest)
        |> add_token(:STRING, string, string)
        |> add_lines(line_delta)
        |> scan()
    end
  end

  defp number(%__MODULE__{input: input} = scanner) do
    {number_str, rest} = handle_number(input, [], false)
    {num_literal, _} = Float.parse(number_str)
    scanner |> push_token(rest, :NUMBER, number_str, num_literal)
  end

  @reserved_words ~w(and class else false for fun if nil or print return super this true var while)

  defp identifier(%__MODULE__{input: <<hd, rest::binary>>} = scanner) do
    {id_str, rest} = handle_identifier(rest, [hd])
    token_type = if id_str in @reserved_words, do: :"#{String.upcase(id_str)}", else: :IDENTIFIER
    scanner |> push_token(rest, token_type, id_str)
  end

  defp handle_number("." <> _ = input, acc, true) do
    {to_string(Enum.reverse(acc)), input}
  end

  defp handle_number("." <> rest, acc, false) do
    handle_number(rest, [?. | acc], true)
  end

  defp handle_number(<<d, rest::binary>>, acc, seen_dot) when is_digit(d) do
    handle_number(rest, [d | acc], seen_dot)
  end

  defp handle_number(rest, acc, _) do
    {to_string(Enum.reverse(acc)), rest}
  end

  defp handle_identifier(<<char, rest::binary>>, acc) when is_alphanum(char) do
    handle_identifier(rest, [char | acc])
  end

  defp handle_identifier(rest, acc) do
    {to_string(Enum.reverse(acc)), rest}
  end

  defp handle_unknown_character(%__MODULE__{} = scanner) do
    <<char::binary-size(1), rest::binary>> = scanner.input
    Loex.error(scanner.current_line, "Unexpected character `#{char}'")
    scanner |> ignore_character(rest)
  end

  defp with_input(%__MODULE__{} = scanner, input), do: %__MODULE__{scanner | input: input}

  defp with_errors(%__MODULE__{} = scanner), do: %__MODULE__{scanner | has_errors: true}

  defp add_line(%__MODULE__{current_line: line} = scanner),
    do: %__MODULE__{scanner | current_line: line + 1}

  defp add_lines(%__MODULE__{current_line: line} = scanner, line_delta),
    do: %__MODULE__{scanner | current_line: line + line_delta}

  defp add_token(%__MODULE__{tokens: tokens, current_line: line} = scanner, type, lexeme, literal) do
    token = Token.new(type, lexeme, literal, line)
    %__MODULE__{scanner | tokens: [token | tokens]}
  end
end
