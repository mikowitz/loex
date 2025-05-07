defmodule LoexTest.Support.Generators do
  alias Loex.Token

  @single_character_tokens [
    LEFT_PAREN: "(",
    RIGHT_PAREN: ")",
    LEFT_BRACE: "{",
    RIGHT_BRACE: "}",
    COMMA: ",",
    DOT: ".",
    MINUS: "-",
    PLUS: "+",
    SEMICOLON: ";",
    STAR: "*"
  ]

  @operators [
    BANG: "!",
    BANG_EQUAL: "!=",
    EQUAL: "=",
    EQUAL_EQUAL: "==",
    LESS: "<",
    LESS_EQUAL: "<=",
    GREATER: ">",
    GREATER_EQUAL: ">="
  ]

  def token do
    @single_character_tokens
    |> Enum.map(fn {type, lexeme} -> {lexeme, %Token{type: type, lexeme: lexeme}} end)
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def operator do
    @operators
    |> Enum.map(fn {type, lexeme} -> {lexeme, %Token{type: type, lexeme: lexeme}} end)
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def invalid_char do
    ~w(@ # $ % ^)
    |> Enum.map(&{&1, :invalid})
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def token_or_invalid do
    StreamData.one_of([token(), invalid_char()])
  end

  def token_or_operator do
    StreamData.one_of([token(), operator()])
  end

  def finalize_tokens(tokens) do
    tokens
    |> Enum.filter(&is_struct(&1, Token))
    |> correct_operators()
    |> Kernel.++([Token.eof()])
    |> Enum.map(&%Token{&1 | line: 1})
  end

  defp correct_operators([]), do: []
  defp correct_operators(tokens), do: correct_operators(tokens, [])

  defp correct_operators([], acc), do: Enum.reverse(acc)
  defp correct_operators([t], acc), do: Enum.reverse([t | acc])

  defp correct_operators([%Token{type: type} = t | [t2 | rest] = tail], acc)
       when type in ~w(BANG EQUAL LESS GREATER)a do
    case t2.type do
      :EQUAL -> correct_operators(rest, [extend_operator(t) | acc])
      :EQUAL_EQUAL -> correct_operators([Token.equal() | rest], [extend_operator(t) | acc])
      _ -> correct_operators(tail, [t | acc])
    end
  end

  defp correct_operators([a | rest], acc) do
    correct_operators(rest, [a | acc])
  end

  defp extend_operator(%Token{type: :BANG} = token),
    do: %Token{token | type: :BANG_EQUAL, lexeme: "!="}

  defp extend_operator(%Token{type: :EQUAL} = token),
    do: %Token{token | type: :EQUAL_EQUAL, lexeme: "=="}

  defp extend_operator(%Token{type: :LESS} = token),
    do: %Token{token | type: :LESS_EQUAL, lexeme: "<="}

  defp extend_operator(%Token{type: :GREATER} = token),
    do: %Token{token | type: :GREATER_EQUAL, lexeme: ">="}
end
