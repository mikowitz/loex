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

      assert_tokens(scanner, [])
    end

    property "with a single token as input" do
      check all {lex, token} <- unambiguous_token() do
        scanner = Scanner.new(lex)
        scanner = Scanner.scan(scanner)

        assert_tokens(scanner, [token])
      end
    end

    property "with a series of valid and invalid tokens, comments and whitespace" do
      check all {input, output} <-
                  generate_input_and_expected_output(
                    one_of([
                      unambiguous_token(),
                      invalid_character(),
                      operator(),
                      comment(),
                      whitespace()
                    ])
                  ) do
        tokens = Enum.filter(output, &is_struct(&1, Token))
        scanner = Scanner.new(input)

        errors =
          capture_io(:stderr, fn ->
            scanner = Scanner.scan(scanner)

            assert_tokens(scanner, tokens)
          end)

        assert_stderr_matches(errors, output)
      end
    end
  end

  defp assert_stderr_matches(output, tokens) do
    Enum.filter(tokens, fn
      {:invalid_char, _, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {:invalid_char, char, line} ->
      assert output =~ "[line #{line}] Error: Unexpected character `#{char}'"
    end)
  end

  defp assert_tokens(%Scanner{} = scanner, tokens) do
    assert scanner.tokens ==
             tokens ++
               [
                 Token.new(:EOF, "", nil, scanner.current_line)
               ]
  end
end
