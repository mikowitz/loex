defmodule Loex.Token do
  @moduledoc """
  Models a token in the Lox language. Generated and returned by `Loex.Scaner`.
  """

  use Loex.Constants

  defstruct [:type, :lexeme, :literal, :line]

  @typedoc false
  @type token_type ::
          :EOF
          | :LEFT_PAREN
          | :RIGHT_PAREN
          | :LEFT_BRACE
          | :RIGHT_BRACE
          | :COMMA
          | :DOT
          | :MINUS
          | :PLUS
          | :SEMICOLON
          | :SLASH
          | :STAR
          | :SLASH
          | :BANG_EQUAL
          | :EQUAL_EQUAL
          | :LESS_EQUAL
          | :GREATER_EQUAL
          | :BANG
          | :EQUAL
          | :LESS
          | :GREATER
          | :STRING
          | :IDENTIFIER
          | :AND
          | :CLASS
          | :ELSE
          | :FALSE
          | :FOR
          | :FUN
          | :IF
          | :NIL
          | :OR
          | :PRINT
          | :RETURN
          | :SUPER
          | :THIS
          | :TRUE
          | :VAR
          | :WHILE

  @type t :: %__MODULE__{
          type: token_type(),
          lexeme: String.t(),
          literal: String.t() | number() | nil,
          line: pos_integer()
        }

  def eof, do: %__MODULE__{type: :EOF, lexeme: ""}

  def left_paren, do: %__MODULE__{type: :LEFT_PAREN, lexeme: "("}
  def right_paren, do: %__MODULE__{type: :RIGHT_PAREN, lexeme: ")"}
  def left_brace, do: %__MODULE__{type: :LEFT_BRACE, lexeme: "{"}
  def right_brace, do: %__MODULE__{type: :RIGHT_BRACE, lexeme: "}"}
  def comma, do: %__MODULE__{type: :COMMA, lexeme: ","}
  def dot, do: %__MODULE__{type: :DOT, lexeme: "."}
  def minus, do: %__MODULE__{type: :MINUS, lexeme: "-"}
  def plus, do: %__MODULE__{type: :PLUS, lexeme: "+"}
  def semicolon, do: %__MODULE__{type: :SEMICOLON, lexeme: ";"}
  def star, do: %__MODULE__{type: :STAR, lexeme: "*"}
  def slash, do: %__MODULE__{type: :SLASH, lexeme: "/"}
  def bang_equal, do: %__MODULE__{type: :BANG_EQUAL, lexeme: "!="}
  def equal_equal, do: %__MODULE__{type: :EQUAL_EQUAL, lexeme: "=="}
  def less_equal, do: %__MODULE__{type: :LESS_EQUAL, lexeme: "<="}
  def greater_equal, do: %__MODULE__{type: :GREATER_EQUAL, lexeme: ">="}
  def bang, do: %__MODULE__{type: :BANG, lexeme: "!"}
  def equal, do: %__MODULE__{type: :EQUAL, lexeme: "="}
  def less, do: %__MODULE__{type: :LESS, lexeme: "<"}
  def greater, do: %__MODULE__{type: :GREATER, lexeme: ">"}

  def string(str) do
    %__MODULE__{type: :STRING, lexeme: str, literal: str}
  end

  def number(n) do
    {lit, ""} = Float.parse(n)
    %__MODULE__{type: :NUMBER, lexeme: n, literal: lit}
  end

  def identifier(identifier) do
    %__MODULE__{type: :IDENTIFIER, lexeme: identifier}
  end

  def reserved_word(word) when word in @reserved_words do
    %__MODULE__{type: :"#{String.upcase(word)}", lexeme: word}
  end
end
