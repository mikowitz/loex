defmodule Loex.Token do
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

  @type t :: %__MODULE__{
          type: token_type(),
          lexeme: String.t(),
          literal: String.t() | number() | nil,
          line: pos_integer()
        }

  def eof, do: %__MODULE__{type: :EOF, lexeme: ""}
  def left_paren, do: %__MODULE__{type: :LEFT_PAREN, lexeme: "("}
  def right_paren, do: %__MODULE__{type: :RIGHT_PAREN, lexeme: ")"}
end
