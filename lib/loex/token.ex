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

  %{
    "LEFT_PAREN" => "(",
    "RIGHT_PAREN" => ")",
    "LEFT_BRACE" => "{",
    "RIGHT_BRACE" => "}",
    "COMMA" => ",",
    "DOT" => ".",
    "MINUS" => "-",
    "PLUS" => "+",
    "SEMICOLON" => ";",
    "STAR" => "*",
    "SLASH" => "/",
    "BANG_EQUAL" => "!=",
    "EQUAL_EQUAL" => "==",
    "LESS_EQUAL" => "<=",
    "GREATER_EQUAL" => ">=",
    "BANG" => "!",
    "EQUAL" => "=",
    "LESS" => "<",
    "GREATER" => ">"
  }
  |> Enum.map(fn {type, lexeme} ->
    def unquote(String.to_atom(String.downcase(type)))() do
      %__MODULE__{type: :"#{unquote(type)}", lexeme: unquote(lexeme)}
    end
  end)

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
