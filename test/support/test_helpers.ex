defmodule Loex.Test.Support.TestHelpers do
  use ExUnitProperties
  import StreamData

  alias Loex.Token

  def generate_input_and_expected_output(generator) do
    gen all tokens <- list_of(generator, min_length: 1) do
      {lexemes, tokens} = Enum.unzip(tokens)

      {Enum.join(lexemes), process_tokens(tokens)}
    end
  end

  defp process_tokens(tokens), do: process_tokens(tokens, [])

  defp process_tokens([], acc), do: Enum.reverse(acc)

  defp process_tokens(tokens, acc) do
    case tokens do
      [%Token{type: type, lexeme: lex, line: line}, %Token{type: :EQUAL} | rest]
      when type in ~w(BANG EQUAL LESS GREATER)a ->
        process_tokens(rest, [Token.new(:"#{type}_EQUAL", lex <> "=", nil, line) | acc])

      [%Token{type: type, lexeme: lex, line: line}, %Token{type: :EQUAL_EQUAL} | rest]
      when type in ~w(BANG EQUAL LESS GREATER)a ->
        process_tokens([Token.new(:EQUAL, "=", nil, line) | rest], [
          Token.new(:"#{type}_EQUAL", lex <> "=", nil, line) | acc
        ])

      [t | rest] ->
        process_tokens(rest, [t | acc])
    end
  end
end
