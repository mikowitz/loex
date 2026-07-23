defmodule Loex.Scanner do
  @moduledoc """
  Scans an input string and returns a series of [Loex.Tokens],
  reporting any errors along the way
  """

  defstruct [:source, :runtime, tokens: [], start: 0, current: 0, line: 1]

  @type t :: %__MODULE__{
          source: charlist(),
          runtime: Loex.t(),
          tokens: [Loex.Token.t()],
          start: non_neg_integer(),
          current: non_neg_integer(),
          line: pos_integer()
        }

  @single_char_tokens [
    LEFT_PAREN: ?(,
    RIGHT_PAREN: ?),
    LEFT_BRACE: ?{,
    RIGHT_BRACE: ?},
    COMMA: ?,,
    DOT: ?.,
    MINUS: ?-,
    PLUS: ?+,
    SEMICOLON: ?;,
    STAR: ?*
  ]
  @two_char_operators [
    BANG: ?!,
    EQUAL: ?=,
    LESS: ?<,
    GREATER: ?>
  ]

  @keywords ~w(and class else false for fun if nil or print return super this true var while)

  alias Loex.Token

  defguard digit?(c) when c >= ?0 and c <= ?9
  defguard alpha?(c) when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or c == ?_
  defguard alpha_numeric?(c) when digit?(c) or alpha?(c)

  def new(source, runtime \\ %Loex{}) do
    %__MODULE__{source: to_charlist(source), runtime: runtime}
  end

  def scan(%__MODULE__{source: []} = scanner) do
    scanner = add_token(scanner, Token.new(:EOF, "", nil, scanner.line))
    %{scanner | tokens: Enum.reverse(scanner.tokens)}
  end

  for {type, lexeme} <- @single_char_tokens do
    def scan(%__MODULE__{source: [unquote(lexeme) | _rest]} = scanner),
      do: scanner |> add_token(unquote(type)) |> advance() |> scan()
  end

  for {type, lexeme} <- @two_char_operators do
    def scan(%__MODULE__{source: [unquote(lexeme) | rest]} = scanner) do
      {token_type, len} =
        case rest do
          [?= | _rest] -> {:"#{unquote(type)}_EQUAL", 2}
          _ -> {unquote(type), 1}
        end

      scanner |> add_token(token_type, len) |> advance(len) |> scan()
    end
  end

  def scan(%__MODULE__{source: [?/ | rest]} = scanner) do
    case rest do
      [?/ | rest] ->
        {comment, rest} = Enum.split_while(rest, &(&1 != ?\n))

        case rest do
          [] ->
            scanner |> advance(length(comment) + 2) |> scan()

          [?\n | rest] ->
            %{scanner | source: rest, line: scanner.line + 1} |> scan()
        end

      _ ->
        scanner |> add_token(:SLASH) |> advance() |> scan()
    end
  end

  def scan(%__MODULE__{source: [c | _rest]} = scanner) when c in ~c"\s\r\t" do
    scanner |> advance() |> scan()
  end

  def scan(%__MODULE__{source: [?\n | rest]} = scanner) do
    %{scanner | source: rest, line: scanner.line + 1} |> scan()
  end

  def scan(%__MODULE__{source: [?" | rest]} = scanner) do
    {string, rest} = Enum.split_while(rest, &(&1 != ?"))

    case rest do
      [] ->
        runtime =
          Loex.error(
            scanner.runtime,
            scanner.line,
            "Unterminated string."
          )

        %{scanner | source: rest, runtime: runtime} |> advance() |> scan()

      [?" | rest] ->
        newlines = Enum.count(string, &(&1 == ?n))

        token =
          Token.new(
            :STRING,
            to_string([?" | string ++ [?"]]),
            to_string(string),
            scanner.line
          )

        %{
          scanner
          | tokens: [token | scanner.tokens],
            source: rest,
            line: scanner.line + newlines
        }
        |> scan()
    end
  end

  def scan(%__MODULE__{source: [c | rest]} = scanner) when digit?(c) do
    {rest, number} = scan_number(rest, [c], false)
    lexeme = to_string(number)
    {literal, ""} = Float.parse(lexeme)
    token = Token.new(:NUMBER, lexeme, literal, scanner.line)
    %{scanner | source: rest} |> add_token(token) |> scan()
  end

  def scan(%__MODULE__{source: [c | rest]} = scanner) when alpha?(c) do
    {rest, identifier} = scan_identifier(rest, [c])
    lexeme = to_string(identifier)

    token_type =
      if lexeme in @keywords do
        lexeme |> String.upcase() |> String.to_atom()
      else
        :IDENTIFIER
      end

    token = Token.new(token_type, lexeme, nil, scanner.line)
    %{scanner | source: rest, tokens: [token | scanner.tokens]} |> scan()
  end

  def scan(%__MODULE__{source: [c | _rest]} = scanner) do
    runtime =
      Loex.error(
        scanner.runtime,
        scanner.line,
        "Unexpected character: `#{to_string([c])}`."
      )

    %{scanner | runtime: runtime} |> advance() |> scan()
  end

  defp scan_number([?. | _] = all, acc, true), do: {all, Enum.reverse(acc)}

  defp scan_number([?., c | rest], acc, false) when digit?(c),
    do: scan_number(rest, [c, ?. | acc], true)

  defp scan_number([c | rest], acc, seen_decimal) when digit?(c),
    do: scan_number(rest, [c | acc], seen_decimal)

  defp scan_number(rest, acc, _seen_decimal), do: {rest, Enum.reverse(acc)}

  defp scan_identifier([c | rest], acc) when alpha_numeric?(c),
    do: scan_identifier(rest, [c | acc])

  defp scan_identifier(rest, acc), do: {rest, Enum.reverse(acc)}

  defp add_token(%__MODULE__{tokens: tokens} = scanner, %Token{} = token) do
    %{scanner | tokens: [token | tokens]}
  end

  defp add_token(%__MODULE__{tokens: tokens} = scanner, token_type, len \\ 1)
       when is_atom(token_type) do
    token =
      Token.new(token_type, to_string(Enum.take(scanner.source, len)), nil, scanner.line)

    %{scanner | tokens: [token | tokens]}
  end

  defp advance(scanner, len \\ 1)

  defp advance(%__MODULE__{source: []} = scanner, _len) do
    scanner
  end

  defp advance(%__MODULE__{source: source} = scanner, len) do
    %{scanner | source: Enum.drop(source, len)}
  end
end
