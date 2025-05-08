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
    STAR: "*",
    SLASH: "/"
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
    ~w(@ # $ % ^ &)
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

  def comment do
    StreamData.string(:ascii)
    |> StreamData.map(&{"// #{&1}", :comment})
  end

  def comment_with_newline do
    comment() |> StreamData.map(fn {s, :comment} -> {"#{s}\n", :comment_with_newline} end)
  end

  def string do
    StreamData.string(:alphanumeric)
    |> StreamData.map(fn s ->
      {"\"#{s}\"", Token.string(s)}
    end)
  end

  def whitespace do
    [{"\n", :newline}, {" ", :space}, {"\t", :tab}]
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def lox_content do
    StreamData.list_of(
      StreamData.one_of([
        token(),
        operator(),
        invalid_char(),
        comment(),
        comment_with_newline(),
        whitespace(),
        string()
      ]),
      min_length: 1
    )
  end
end
