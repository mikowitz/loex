defmodule LoexTest.Support.Generators do
  alias Loex.Token

  @tokens [
    {"(", %Token{type: :LEFT_PAREN, lexeme: "("}},
    {")", %Token{type: :RIGHT_PAREN, lexeme: ")"}},
    {"{", %Token{type: :LEFT_BRACE, lexeme: "{"}},
    {"}", %Token{type: :RIGHT_BRACE, lexeme: "}"}},
    {",", %Token{type: :COMMA, lexeme: ","}},
    {".", %Token{type: :DOT, lexeme: "."}},
    {"-", %Token{type: :MINUS, lexeme: "-"}},
    {"+", %Token{type: :PLUS, lexeme: "+"}},
    {";", %Token{type: :SEMICOLON, lexeme: ";"}},
    {"*", %Token{type: :STAR, lexeme: "*"}},
    {"!", %Token{type: :BANG, lexeme: "!"}},
    {"!=", %Token{type: :BANG_EQUAL, lexeme: "!="}},
    {"=", %Token{type: :EQUAL, lexeme: "="}},
    {"==", %Token{type: :EQUAL_EQUAL, lexeme: "=="}},
    {"<", %Token{type: :LESS, lexeme: "<"}},
    {"<=", %Token{type: :LESS_EQUAL, lexeme: "<="}},
    {">", %Token{type: :GREATER, lexeme: ">"}},
    {">=", %Token{type: :GREATER_EQUAL, lexeme: ">="}}
  ]

  @invalid_characters ~w(@ # ^)

  def token do
    @tokens
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def invalid_character do
    @invalid_characters
    |> Enum.map(&{&1, nil})
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def single_line_input do
    token()
    |> StreamData.list_of(min_length: 1)
  end

  def single_line_input_with_invalid_chars do
    StreamData.one_of([token(), invalid_character()])
    |> StreamData.list_of(min_length: 1)
  end

  def complete_tokens(tokens \\ []) do
    tokens
    |> reduce_equals()
    |> Enum.reject(&is_nil/1)
    |> List.wrap()
    |> then(&(&1 ++ [Token.eof()]))
    |> Enum.map(&%{&1 | line: 1})
  end

  defp reduce_equals([]), do: []
  defp reduce_equals(l), do: reduce_equals(l, [])

  defp reduce_equals([], acc), do: Enum.reverse(acc)
  defp reduce_equals([x], acc), do: Enum.reverse([x | acc])
  defp reduce_equals([nil | rest], acc), do: reduce_equals(rest, acc)
  defp reduce_equals([a, nil | rest], acc), do: reduce_equals(rest, [a | acc])

  defp reduce_equals([a, b | rest], acc) do
    case {a.type, b.type} do
      {:EQUAL, :EQUAL_EQUAL} ->
        reduce_equals([Token.equal() | rest], [Token.equal_equal() | acc])

      {:BANG, :EQUAL_EQUAL} ->
        reduce_equals([Token.equal() | rest], [Token.bang_equal() | acc])

      {:LESS, :EQUAL_EQUAL} ->
        reduce_equals([Token.equal() | rest], [Token.less_equal() | acc])

      {:GREATER, :EQUAL_EQUAL} ->
        reduce_equals([Token.equal() | rest], [Token.greater_equal() | acc])

      {:EQUAL, :EQUAL} ->
        reduce_equals(rest, [Token.equal_equal() | acc])

      {:BANG, :EQUAL} ->
        reduce_equals(rest, [Token.bang_equal() | acc])

      {:LESS, :EQUAL} ->
        reduce_equals(rest, [Token.less_equal() | acc])

      {:GREATER, :EQUAL} ->
        reduce_equals(rest, [Token.greater_equal() | acc])

      _ ->
        reduce_equals([b | rest], [a | acc])
    end
  end
end
