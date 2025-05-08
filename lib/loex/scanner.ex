defmodule Loex.Scanner do
  @moduledoc """
  Scanner for the Lox language. 

  Takes as input a string containing a Lox program and returns
  a list of tokens and an error state.
  """
  use Loex.Constants

  alias Loex.Token

  defguardp is_alpha(c) when c in ?a..?z or c in ?A..?Z or c == ?_
  defguardp is_digit(c) when c in ?0..?9
  defguardp is_alphanum(c) when is_alpha(c) or is_digit(c)

  defstruct [:input, tokens: [], current_line: 1, has_errors: false]

  @type t :: %__MODULE__{
          input: binary(),
          tokens: [Token.t()],
          current_line: pos_integer(),
          has_errors: boolean()
        }

  @spec new(binary()) :: t()
  def new(input) when is_binary(input), do: %__MODULE__{input: input}

  @spec scan(t()) :: t()
  def scan(%__MODULE__{input: ""} = scanner) do
    scanner |> add_token(Token.eof()) |> finalize()
  end

  def scan(%__MODULE__{input: "(" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.left_paren()) |> scan()
  end

  def scan(%__MODULE__{input: ")" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.right_paren()) |> scan()
  end

  def scan(%__MODULE__{input: "{" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.left_brace()) |> scan()
  end

  def scan(%__MODULE__{input: "}" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.right_brace()) |> scan()
  end

  def scan(%__MODULE__{input: "," <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.comma()) |> scan()
  end

  def scan(%__MODULE__{input: "." <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.dot()) |> scan()
  end

  def scan(%__MODULE__{input: "-" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.minus()) |> scan()
  end

  def scan(%__MODULE__{input: "+" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.plus()) |> scan()
  end

  def scan(%__MODULE__{input: ";" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.semicolon()) |> scan()
  end

  def scan(%__MODULE__{input: "*" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.star()) |> scan()
  end

  def scan(%__MODULE__{input: "!=" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.bang_equal()) |> scan()
  end

  def scan(%__MODULE__{input: "==" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.equal_equal()) |> scan()
  end

  def scan(%__MODULE__{input: "<=" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.less_equal()) |> scan()
  end

  def scan(%__MODULE__{input: ">=" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.greater_equal()) |> scan()
  end

  def scan(%__MODULE__{input: "!" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.bang()) |> scan()
  end

  def scan(%__MODULE__{input: "=" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.equal()) |> scan()
  end

  def scan(%__MODULE__{input: "<" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.less()) |> scan()
  end

  def scan(%__MODULE__{input: ">" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.greater()) |> scan()
  end

  def scan(%__MODULE__{input: "//" <> input} = scanner) do
    case String.split(input, "\n", parts: 2) do
      [_rest] -> scanner |> with_input("") |> scan()
      [_comment, rest] -> scanner |> next_line() |> with_input(rest) |> scan()
    end
  end

  def scan(%__MODULE__{input: "/" <> input} = scanner) do
    scanner |> with_input(input) |> add_token(Token.slash()) |> scan()
  end

  def scan(%__MODULE__{input: "\n" <> input} = scanner) do
    scanner |> next_line() |> with_input(input) |> scan()
  end

  def scan(%__MODULE__{input: " " <> input} = scanner) do
    scanner |> with_input(input) |> scan()
  end

  def scan(%__MODULE__{input: "\t" <> input} = scanner) do
    scanner |> with_input(input) |> scan()
  end

  def scan(%__MODULE__{input: "\"" <> input} = scanner) do
    case String.split(input, "\"", parts: 2) do
      [str, rest] ->
        line_delta = to_charlist(str) |> Enum.count(&(&1 == ?\n))

        scanner
        |> with_input(rest)
        |> add_token(Token.string(str))
        |> add_lines(line_delta)
        |> scan()

      [_str] ->
        Loex.error(scanner.current_line, "Unterminated string")
        scanner |> with_input("") |> with_errors() |> scan()
    end
  end

  def scan(%__MODULE__{input: <<n, input::binary>>} = scanner) when is_digit(n) do
    {num, rest} = extract_number(input, [n], false)
    scanner |> with_input(rest) |> add_token(Token.number(num)) |> scan()
  end

  def scan(%__MODULE__{input: <<char, input::binary>>} = scanner)
      when is_alpha(char) do
    {token, rest} = extract_identifier(input, [char])
    scanner |> with_input(rest) |> add_token(token) |> scan()
  end

  def scan(%__MODULE__{input: <<char::binary-size(1), input::binary>>} = scanner) do
    Loex.error(scanner.current_line, "Unexpected character #{char}")
    scanner |> with_input(input) |> with_errors() |> scan()
  end

  #############
  ## PRIVATE ##
  #############

  defp extract_identifier(<<char, rest::binary>>, acc) when is_alphanum(char) do
    extract_identifier(rest, [char | acc])
  end

  defp extract_identifier(rest, acc) do
    ident = to_string(Enum.reverse(acc))

    token =
      case ident in @reserved_words do
        true -> Token.reserved_word(ident)
        false -> Token.identifier(ident)
      end

    {token, rest}
  end

  defp extract_number(<<n, rest::binary>>, acc, seen_dot) when is_digit(n) do
    extract_number(rest, [n | acc], seen_dot)
  end

  defp extract_number("." <> rest, acc, false) do
    extract_number(rest, [?. | acc], true)
  end

  defp extract_number(rest, acc, _), do: {to_string(Enum.reverse(acc)), rest}

  #############
  ## HELPERS ##
  #############

  defp with_input(%__MODULE__{} = scanner, input) do
    %__MODULE__{scanner | input: input}
  end

  defp with_errors(%__MODULE__{} = scanner) do
    %__MODULE__{scanner | has_errors: true}
  end

  defp add_lines(%__MODULE__{current_line: line} = scanner, line_delta) do
    %__MODULE__{scanner | current_line: line + line_delta}
  end

  defp next_line(%__MODULE__{current_line: line} = scanner) do
    %__MODULE__{scanner | current_line: line + 1}
  end

  defp add_token(%__MODULE__{current_line: line, tokens: tokens} = scanner, %Token{} = token) do
    token = %Token{token | line: line}
    %__MODULE__{scanner | tokens: [token | tokens]}
  end

  defp finalize(%__MODULE__{tokens: tokens} = scanner) do
    %__MODULE__{scanner | tokens: Enum.reverse(tokens)}
  end
end
