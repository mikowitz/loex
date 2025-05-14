defmodule Loex.Scanner do
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
      "//" <> _ -> scanner |> comment() |> scan()
      "/*" <> _ -> scanner |> block_comment() |> scan()
      "/" <> rest -> scanner |> with_input(rest) |> add_token(:SLASH, "/") |> scan()
      "\t" <> rest -> scanner |> with_input(rest) |> scan()
      " " <> rest -> scanner |> with_input(rest) |> scan()
      "\n" <> rest -> scanner |> with_input(rest) |> add_line() |> scan()
      "\"" <> rest -> scanner |> with_input(rest) |> string() |> scan()
      <<d, _rest::binary>> when is_digit(d) -> scanner |> number() |> scan()
      <<a, r::binary>> when is_alpha(a) -> scanner |> with_input(r) |> identifier(a) |> scan()
      _ -> handle_unknown_character(scanner)
    end
  end

  defp comment(%__MODULE__{input: input} = scanner) do
    case String.split(input, "\n", parts: 2) do
      [_rest] ->
        scanner |> with_input("")

      [_comment, rest] ->
        scanner |> with_input(rest) |> add_line()
    end
  end

  defp block_comment(%__MODULE__{input: input} = scanner) do
    case String.split(input, "*/", parts: 2) do
      [_rest] ->
        scanner |> with_input("")

      [comment, rest] ->
        line_delta = String.codepoints(comment) |> Enum.count(&(&1 == "\n"))
        scanner |> with_input(rest) |> add_lines(line_delta)
    end
  end

  defp string(%__MODULE__{input: input} = scanner) do
    case String.split(input, "\"", parts: 2) do
      [_rest] ->
        Loex.error(scanner.current_line, "Unterminated string")
        scanner |> with_errors() |> with_input("")

      [string, rest] ->
        line_delta = String.codepoints(string) |> Enum.count(&(&1 == "\n"))
        scanner |> with_input(rest) |> add_token(:STRING, string, string) |> add_lines(line_delta)
    end
  end

  defp number(%__MODULE__{input: input} = scanner) do
    {number_str, rest} = handle_number(input, [], false)
    {num_literal, _} = Float.parse(number_str)
    scanner |> with_input(rest) |> add_token(:NUMBER, number_str, num_literal)
  end

  @reserved_words ~w(and class else false for fun if nil or print return super this true var while)

  defp identifier(%__MODULE__{input: input} = scanner, hd) do
    {id_str, rest} = handle_identifier(input, [hd])
    token_type = if id_str in @reserved_words, do: :"#{String.upcase(id_str)}", else: :IDENTIFIER
    scanner |> with_input(rest) |> add_token(token_type, id_str, nil)
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
