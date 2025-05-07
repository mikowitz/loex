defmodule Loex.Token do
  defstruct [:type, :lexeme, :literal, :line]

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
  def bang_equal, do: %__MODULE__{type: :BANG_EQUAL, lexeme: "!="}
  def bang, do: %__MODULE__{type: :BANG, lexeme: "!"}
  def equal_equal, do: %__MODULE__{type: :EQUAL_EQUAL, lexeme: "=="}
  def equal, do: %__MODULE__{type: :EQUAL, lexeme: "="}
  def less_equal, do: %__MODULE__{type: :LESS_EQUAL, lexeme: "<="}
  def less, do: %__MODULE__{type: :LESS, lexeme: "<"}
  def greater_equal, do: %__MODULE__{type: :GREATER_EQUAL, lexeme: ">="}
  def greater, do: %__MODULE__{type: :GREATER, lexeme: ">"}
end
