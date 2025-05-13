defmodule Loex.Test.Support.TestHelpers do
  use ExUnitProperties
  import StreamData

  alias Loex.Token

  def generate_input_and_expected_output(generator) do
    gen all tokens <- list_of(generator, min_length: 1) do
      tokens = Enum.intersperse(tokens, {" ", :space})

      {lexemes, tokens} = Enum.unzip(tokens)

      {Enum.join(lexemes, " "), process_tokens(tokens)}
    end
  end

  defp process_tokens(tokens), do: process_tokens(tokens, 1, [])

  defp process_tokens([], _line, acc), do: Enum.reverse(acc)

  defp process_tokens(tokens, line, acc) do
    case tokens do
      [%Token{type: :STRING, literal: str} = t | rest] ->
        line_delta = String.codepoints(str) |> Enum.count(&(&1 == "\n"))
        process_tokens(rest, line + line_delta, [%Token{t | line: line} | acc])

      [%Token{} = t | rest] ->
        process_tokens(rest, line, [%Token{t | line: line} | acc])

      [:newline | rest] ->
        process_tokens(rest, line + 1, acc)

      [:comment | rest] ->
        process_tokens(rest, line + 1, acc)

      [{:invalid_char, c} | rest] ->
        process_tokens(rest, line, [{:invalid_char, c, line} | acc])

      [t | rest] ->
        process_tokens(rest, line, [t | acc])
    end
  end
end
