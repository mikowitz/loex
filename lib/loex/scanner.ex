defmodule Loex.Scanner do
  alias Loex.Token
  defstruct [:input, tokens: [], has_errors: false, current_line: 1]

  def new(input), do: %__MODULE__{input: input}

  def scan(%__MODULE__{input: ""} = scanner) do
    scanner |> add_token(Token.eof()) |> finalize()
  end

  def scan(%__MODULE__{input: "(" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.left_paren()) |> scan()

  def scan(%__MODULE__{input: ")" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.right_paren()) |> scan()

  def scan(%__MODULE__{input: "{" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.left_brace()) |> scan()

  def scan(%__MODULE__{input: "}" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.right_brace()) |> scan()

  def scan(%__MODULE__{input: "," <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.comma()) |> scan()

  def scan(%__MODULE__{input: "." <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.dot()) |> scan()

  def scan(%__MODULE__{input: "-" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.minus()) |> scan()

  def scan(%__MODULE__{input: "+" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.plus()) |> scan()

  def scan(%__MODULE__{input: ";" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.semicolon()) |> scan()

  def scan(%__MODULE__{input: "*" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.star()) |> scan()

  def scan(%__MODULE__{input: "!=" <> _} = scanner),
    do: scanner |> trim() |> trim() |> add_token(Token.bang_equal()) |> scan()

  def scan(%__MODULE__{input: "!" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.bang()) |> scan()

  def scan(%__MODULE__{input: "==" <> _} = scanner),
    do: scanner |> trim() |> trim() |> add_token(Token.equal_equal()) |> scan()

  def scan(%__MODULE__{input: "=" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.equal()) |> scan()

  def scan(%__MODULE__{input: "<=" <> _} = scanner),
    do: scanner |> trim() |> trim() |> add_token(Token.less_equal()) |> scan()

  def scan(%__MODULE__{input: "<" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.less()) |> scan()

  def scan(%__MODULE__{input: ">=" <> _} = scanner),
    do: scanner |> trim() |> trim() |> add_token(Token.greater_equal()) |> scan()

  def scan(%__MODULE__{input: ">" <> _} = scanner),
    do: scanner |> trim() |> add_token(Token.greater()) |> scan()

  def scan(%__MODULE__{input: <<char::binary-size(1), _rest::binary>>} = scanner) do
    Loex.report_error(scanner.current_line, "unexpected character: #{char}")
    scanner |> trim() |> with_errors() |> scan()
  end

  ## PRIVATE ##

  defp trim(%__MODULE__{input: <<_, input::binary>>} = scanner) do
    %__MODULE__{scanner | input: input}
  end

  defp with_errors(%__MODULE__{} = scanner) do
    %__MODULE__{scanner | has_errors: true}
  end

  defp add_token(%__MODULE__{tokens: tokens} = scanner, token) do
    %__MODULE__{scanner | tokens: [%Token{token | line: scanner.current_line} | tokens]}
  end

  defp finalize(%__MODULE__{tokens: tokens} = scanner) do
    %__MODULE__{scanner | tokens: Enum.reverse(tokens)}
  end
end
