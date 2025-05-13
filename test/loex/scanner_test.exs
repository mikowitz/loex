defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  use ExUnitProperties
  import StreamData

  import Loex.Test.Support.Generators
  import Loex.Test.Support.TestHelpers

  alias Loex.Token
  alias Loex.Scanner

  describe "scan/1" do
    test "with empty input" do
      scanner = Scanner.new("")
      scanner = Scanner.scan(scanner)

      assert scanner.tokens == [
               %Token{type: :EOF, lexeme: "", literal: nil, line: 1}
             ]
    end

    property "with a single token as input" do
      check all {lex, token} <- unambiguous_token() do
        scanner = Scanner.new(lex)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == [
                 token,
                 %Token{type: :EOF, lexeme: "", literal: nil, line: 1}
               ]
      end
    end

    property "with a series of unambiguous tokens as input" do
      check all {input, output} <- generate_input_and_expected_output(unambiguous_token()) do
        scanner = Scanner.new(input)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens ==
                 output ++
                   [
                     %Token{type: :EOF, lexeme: "", literal: nil, line: 1}
                   ]
      end
    end

    property "with invalid characters" do
      check all {input, output} <-
                  generate_input_and_expected_output(
                    one_of([unambiguous_token(), invalid_character()])
                  ) do
        tokens = Enum.filter(output, &is_struct(&1, Token))

        errors =
          capture_io(:stderr, fn ->
            scanner = Scanner.new(input)
            scanner = Scanner.scan(scanner)

            assert scanner.tokens ==
                     tokens ++
                       [
                         %Token{type: :EOF, lexeme: "", literal: nil, line: 1}
                       ]
          end)

        Enum.reject(output, &is_struct(&1, Token))
        |> Enum.map(fn {:invalid_char, c} ->
          assert errors =~ "[line 1] Error: Unexpected character `#{c}'"
        end)
      end
    end
  end
end
