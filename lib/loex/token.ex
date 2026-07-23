defmodule Loex.Token do
  @moduledoc """
  Loex token returned by the [Loex.Scanner].
  """

  defstruct [:type, :lexeme, :literal, :loc]

  @type t :: %__MODULE__{
          type: atom(),
          lexeme: bitstring(),
          literal: any(),
          loc: {pos_integer(), pos_integer()}
        }

  def new(type, lexeme, literal, loc) do
    %__MODULE__{type: type, lexeme: lexeme, literal: literal, loc: loc}
  end

  defimpl String.Chars do
    def to_string(%@for{type: type, lexeme: lexeme, literal: literal}) do
      "#Token<#{type} #{lexeme} #{literal}>"
    end
  end
end
