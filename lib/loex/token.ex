defmodule Loex.Token do
  @moduledoc """
  Models a single token in a Lox script
  """

  @token_types [
    :LEFT_PAREN,
    :RIGHT_PAREN,
    :LEFT_BRACE,
    :RIGHT_BRACE,
    :COMMA,
    :DOT,
    :MINUS,
    :PLUS,
    :SEMICOLON,
    :SLASH,
    :STAR,
    :BANG,
    :BANG_EQUAL,
    :EQUAL,
    :EQUAL_EQUAL,
    :GREATER,
    :GREATER_EQUAL,
    :LESS,
    :LESS_EQUAL,
    :IDENTIFIER,
    :STRING,
    :NUMBER,
    :AND,
    :CLASS,
    :ELSE,
    :FALSE,
    :FUN,
    :FOR,
    :IF,
    :NIL,
    :OR,
    :PRINT,
    :RETURN,
    :SUPER,
    :THIS,
    :TRUE,
    :VAR,
    :WHILE,
    :EOF
  ]

  defstruct [:type, :lexeme, :literal, :line]

  def new(type, lexeme, literal, line) when type in @token_types do
    %__MODULE__{type: type, lexeme: lexeme, literal: literal, line: line}
  end
end
