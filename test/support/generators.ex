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

  def token do
    @single_character_tokens
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

  def finalize_tokens(tokens) do
    tokens
    |> Enum.filter(&is_struct(&1, Token))
    |> Kernel.++([Token.eof()])
    |> Enum.map(&%Token{&1 | line: 1})
  end
end
