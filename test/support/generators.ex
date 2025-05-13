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
      STAR: "*"
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
end
