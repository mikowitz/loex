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
          | :BANG_EQUAL
          | :EQUAL_EQUAL
          | :LESS_EQUAL
          | :GREATER_EQUAL
          | :BANG
          | :EQUAL
          | :LESS
          | :GREATER

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
end
