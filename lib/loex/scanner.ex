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

  #############
  ## PRIVATE ##
  #############

  defp with_input(%__MODULE__{} = scanner, input) do
    %__MODULE__{scanner | input: input}
  end

  defp add_token(%__MODULE__{current_line: line, tokens: tokens} = scanner, %Token{} = token) do
    token = %Token{token | line: line}
    %__MODULE__{scanner | tokens: [token | tokens]}
  end

  defp finalize(%__MODULE__{tokens: tokens} = scanner) do
    %__MODULE__{scanner | tokens: Enum.reverse(tokens)}
  end
end
