defmodule Loex.Test.Support.Generators do
  import StreamData

  alias Loex.Token

  def unambiguous_token do
    %{
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
    }
    |> Enum.map(fn {type, lex} ->
      constant({lex, Token.new(type, lex, nil, 1)})
    end)
    |> one_of()
  end

  def invalid_character do
    ~w(@ # $ % ^ &)
    |> Enum.map(fn c -> constant({c, {:invalid_char, c}}) end)
    |> one_of()
  end

  def operator do
    %{
      BANG_EQUAL: "!=",
      BANG: "!",
      EQUAL_EQUAL: "==",
      EQUAL: "=",
      GREATER_EQUAL: ">=",
      GREATER: ">",
      LESS_EQUAL: "<=",
      LESS: "<"
    }
    |> Enum.map(fn {type, lex} ->
      constant({lex, Token.new(type, lex, nil, 1)})
    end)
    |> one_of()
  end

  def comment do
    string(:ascii)
    |> map(fn comment ->
      {"// #{comment}\n", :comment}
    end)
  end

  def whitespace do
    [
      {" ", :space},
      {"\n", :newline},
      {"\t", :tab}
    ]
    |> Enum.map(&constant/1)
    |> one_of()
  end

  def string do
    string(Enum.concat([?a..?z, [?\n]]))
    |> map(fn s ->
      {~s["#{s}"], Token.new(:STRING, s, s, 1)}
    end)
  end

  def number do
    one_of([
      integer(0..999),
      float(min: 0.5, max: 999.5)
    ])
    |> map(fn n ->
      {to_string(n), Token.new(:NUMBER, to_string(n), n * 1.0, 1)}
    end)
  end
end
