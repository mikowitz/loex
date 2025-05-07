defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  use ExUnitProperties
  import LoexTest.Support.Generators

  alias Loex.{Scanner, Token}

  test "an empty input" do
    scanner = Scanner.new("") |> Scanner.scan()

    assert scanner.tokens == [
             %{Token.eof() | line: 1}
           ]

    refute scanner.has_errors
  end

  property "a single line of single character lexemes" do
    check all line <- single_line_input() do
      {chars, tokens} = Enum.unzip(line)
      input = Enum.join(chars)
      tokens = complete_tokens(tokens)

      scanner = Scanner.new(input) |> Scanner.scan()
      assert scanner.tokens == tokens
      refute scanner.has_errors
    end
  end

  property "a single line of single character lexemes with possible invalid characters" do
    check all line <- single_line_input_with_invalid_chars() do
      invalid_chars = Enum.filter(line, &(elem(&1, 1) == nil))

      expected_stderr =
        Enum.map(invalid_chars, fn {c, _} ->
          "[line 1] Error: unexpected character: #{c}"
        end)
        |> Enum.join("\n")

      expected_stderr =
        if String.length(expected_stderr) > 0 do
          expected_stderr <> "\n"
        else
          expected_stderr
        end

      {chars, tokens} = Enum.unzip(line)
      input = Enum.join(chars)
      tokens = complete_tokens(tokens)

      assert capture_io(:stderr, fn ->
               scanner = Scanner.new(input) |> Scanner.scan()
               assert scanner.tokens == tokens

               if Enum.any?(invalid_chars) do
                 assert scanner.has_errors
               else
                 refute scanner.has_errors
               end
             end) == expected_stderr
    end
  end
end
