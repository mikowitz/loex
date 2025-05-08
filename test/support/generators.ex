defmodule LoexTest.Support.Generators do
  @moduledoc false

  alias Loex.Token
  use Loex.Constants

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
    StreamData.frequency([
      {5, StreamData.string(:alphanumeric)},
      {1, StreamData.constant("\n")}
    ])
    |> StreamData.list_of(min_length: 1)
    |> StreamData.map(&Enum.join/1)
    |> StreamData.map(fn s ->
      {"\"#{s}\"", Token.string(s)}
    end)
  end

  def number do
    StreamData.one_of([
      StreamData.integer(0..999),
      # NOTE: small range to avoid scientific notation
      StreamData.float(min: 1, max: 999)
    ])
    |> StreamData.map(&{to_string(&1), Token.number(to_string(&1))})
  end

  def reserved_word do
    @reserved_words
    |> Enum.map(fn w ->
      {
        w,
        %Token{lexeme: w, type: :"#{String.upcase(w)}"}
      }
    end)
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
  end

  def identifier do
    StreamData.string([?_, ?a..?z, ?A..?Z, ?0..?9], min_length: 1)
    |> StreamData.filter(&(&1 not in @reserved_words))
    |> StreamData.filter(fn <<i, _::binary>> ->
      i not in ?0..?9
    end)
    |> StreamData.map(&{&1, %Token{type: :IDENTIFIER, lexeme: &1}})
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
        string(),
        number(),
        reserved_word(),
        identifier()
      ]),
      min_length: 1
    )
  end
end
