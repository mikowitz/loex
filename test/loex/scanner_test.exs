defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true

  import ExUnitProperties

  import LoexTest.Support.Generators

  alias Loex.Token
  alias Loex.Scanner

  describe "scan/1" do
    test "with an empty input" do
      scanner = Scanner.new("")
      scanner = Scanner.scan(scanner)

      assert scanner.tokens == [
               %Token{type: :EOF, lexeme: "", line: 1}
             ]

      refute scanner.has_errors
    end

    property "with a single character token input" do
      check all {str, token} <- token() do
        scanner = Scanner.new(str)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == finalize_tokens([token])

        refute scanner.has_errors
      end
    end

    property "with a single line of single character tokens" do
      check all input <- StreamData.list_of(token(), min_length: 1) do
        {input, tokens} = Enum.unzip(input)
        input = Enum.join(input)
        tokens = finalize_tokens(tokens)

        scanner = Scanner.new(input)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end
  end
end
