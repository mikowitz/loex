defmodule Loex.Scanner do
  alias Loex.Token
  defstruct [:input, tokens: [], current_line: 1, has_errors: false]

  def new(input) when is_binary(input), do: %__MODULE__{input: input}

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

  def scan(%__MODULE__{input: <<char::binary-size(1), input::binary>>} = scanner) do
    Loex.error(scanner.current_line, "Unexpected character #{char}")
    scanner |> with_input(input) |> with_errors() |> scan()
  end

  #############
  ## PRIVATE ##
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
