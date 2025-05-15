defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  use ExUnitProperties

  import Loex.Test.Support.Generators
  import Loex.Test.Support.TestHelpers

  alias Loex.Scanner
  alias Loex.Token

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

    property "with all valid lox tokens" do
      check all {input, output} <- generate_input_and_expected_output(token()) do
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

    test "ternary expression" do
      scanner = Scanner.new("true ? 1 : 3")
      scanner = Scanner.scan(scanner)

      assert_tokens(scanner, [
        Token.new(:TRUE, "true", nil, 1),
        Token.new(:QUESTION_MARK, "?", nil, 1),
        Token.new(:NUMBER, "1", 1.0, 1),
        Token.new(:COLON, ":", nil, 1),
        Token.new(:NUMBER, "3", 3.0, 1)
      ])
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
