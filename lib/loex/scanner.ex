defmodule Loex.Scanner do
  alias Loex.Token
  defstruct [:input, tokens: [], current_line: 1, has_errors: false]

  def new(input) do
    %__MODULE__{input: input}
  end

  def scan(%__MODULE__{input: "", tokens: tokens} = scanner) do
    tokens = [
      Token.new(:EOF, "", nil, scanner.current_line) | tokens
    ]

    %__MODULE__{scanner | tokens: Enum.reverse(tokens)}
  end

  def scan(%__MODULE__{input: input} = scanner) do
    case input do
      "(" <> rest -> scanner |> with_input(rest) |> add_token(:LEFT_PAREN, "(") |> scan()
      ")" <> rest -> scanner |> with_input(rest) |> add_token(:RIGHT_PAREN, ")") |> scan()
      "{" <> rest -> scanner |> with_input(rest) |> add_token(:LEFT_BRACE, "{") |> scan()
      "}" <> rest -> scanner |> with_input(rest) |> add_token(:RIGHT_BRACE, "}") |> scan()
      "," <> rest -> scanner |> with_input(rest) |> add_token(:COMMA, ",") |> scan()
      "." <> rest -> scanner |> with_input(rest) |> add_token(:DOT, ".") |> scan()
      "-" <> rest -> scanner |> with_input(rest) |> add_token(:MINUS, "-") |> scan()
      "+" <> rest -> scanner |> with_input(rest) |> add_token(:PLUS, "+") |> scan()
      ";" <> rest -> scanner |> with_input(rest) |> add_token(:SEMICOLON, ";") |> scan()
      "*" <> rest -> scanner |> with_input(rest) |> add_token(:STAR, "*") |> scan()
      "!=" <> rest -> scanner |> with_input(rest) |> add_token(:BANG_EQUAL, "!=") |> scan()
      "!" <> rest -> scanner |> with_input(rest) |> add_token(:BANG, "!") |> scan()
      "==" <> rest -> scanner |> with_input(rest) |> add_token(:EQUAL_EQUAL, "==") |> scan()
      "=" <> rest -> scanner |> with_input(rest) |> add_token(:EQUAL, "=") |> scan()
      ">=" <> rest -> scanner |> with_input(rest) |> add_token(:GREATER_EQUAL, ">=") |> scan()
      ">" <> rest -> scanner |> with_input(rest) |> add_token(:GREATER, ">") |> scan()
      "<=" <> rest -> scanner |> with_input(rest) |> add_token(:LESS_EQUAL, "<=") |> scan()
      "<" <> rest -> scanner |> with_input(rest) |> add_token(:LESS, "<") |> scan()
      "//" <> _ -> scanner |> handle_comment() |> scan()
      "/" <> rest -> scanner |> with_input(rest) |> add_token(:SLASH, "/") |> scan()
      "\t" <> rest -> scanner |> with_input(rest) |> scan()
      " " <> rest -> scanner |> with_input(rest) |> scan()
      "\n" <> rest -> scanner |> with_input(rest) |> add_line() |> scan()
      "\"" <> rest -> scanner |> with_input(rest) |> handle_string() |> scan()
      <<digit, _rest::binary>> when digit in ?0..?9 -> scanner |> handle_number() |> scan()
      _ -> handle_unknown_character(scanner)
    end
  end

  defp handle_number(%__MODULE__{input: input} = scanner) do
    {number_str, rest} = handle_number(input, [], false)
    {num_literal, _} = Float.parse(number_str)
    scanner |> with_input(rest) |> add_token(:NUMBER, number_str, num_literal)
  end

  defp handle_number("." <> _ = input, acc, true) do
    {to_string(Enum.reverse(acc)), input}
  end

  defp handle_number("." <> rest, acc, false) do
    handle_number(rest, [?. | acc], true)
  end

  defp handle_number(<<digit, rest::binary>>, acc, seen_dot) when digit in ?0..?9 do
    handle_number(rest, [digit | acc], seen_dot)
  end

  defp handle_number(rest, acc, _) do
    {to_string(Enum.reverse(acc)), rest}
  end

  defp handle_string(%__MODULE__{input: input} = scanner) do
    case String.split(input, "\"", parts: 2) do
      [_rest] ->
        Loex.error(scanner.current_line, "Unterminated string")
        scanner |> with_errors() |> with_input("")

      [string, rest] ->
        line_delta = String.codepoints(string) |> Enum.count(&(&1 == "\n"))
        scanner |> with_input(rest) |> add_token(:STRING, string, string) |> add_lines(line_delta)
    end
  end

  defp handle_comment(%__MODULE__{input: input} = scanner) do
    case String.split(input, "\n", parts: 2) do
      [_rest] ->
        scanner |> with_input("")

      [_comment, rest] ->
        scanner |> with_input(rest) |> add_line()
    end
  end

  defp handle_unknown_character(%__MODULE__{} = scanner) do
    <<char::binary-size(1), rest::binary>> = scanner.input
    Loex.error(scanner.current_line, "Unexpected character `#{char}'")
    %__MODULE__{scanner | input: rest} |> scan()
  end

  defp with_input(%__MODULE__{} = scanner, input), do: %__MODULE__{scanner | input: input}

  defp with_errors(%__MODULE__{} = scanner), do: %__MODULE__{scanner | has_errors: true}

  defp add_line(%__MODULE__{current_line: line} = scanner),
    do: %__MODULE__{scanner | current_line: line + 1}

  defp add_lines(%__MODULE__{current_line: line} = scanner, line_delta),
    do: %__MODULE__{scanner | current_line: line + line_delta}

  defp add_token(
         %__MODULE__{tokens: tokens, current_line: line} = scanner,
         type,
         lexeme,
         literal \\ nil
       ) do
    token = Token.new(type, lexeme, literal, line)
    %__MODULE__{scanner | tokens: [token | tokens]}
  end
end
