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
      _ -> handle_unknown_character(scanner)
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

  defp add_line(%__MODULE__{current_line: line} = scanner),
    do: %__MODULE__{scanner | current_line: line + 1}

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
