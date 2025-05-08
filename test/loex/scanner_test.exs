defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import ExUnitProperties

  import LoexTest.Support.Generators
  import LoexTest.Support.TestCaseHelpers

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
        {scanner, tokens} = generate_scanner_and_expected_tokens(input)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "with invalid characters" do
      check all input <-
                  StreamData.list_of(StreamData.one_of([invalid_char(), whitespace()]),
                    min_length: 1
                  ) do
        {scanner, tokens} = generate_scanner_and_expected_tokens(input)

        invalid_chars =
          String.split(scanner.input, "\n")
          |> Enum.with_index(1)
          |> Enum.map(fn {line, i} ->
            String.codepoints(line)
            |> Enum.filter(&(&1 in ~w(@ # $ % ^ &)))
            |> Enum.map(&{&1, i})
          end)
          |> List.flatten()

        expected_stderr =
          Enum.map(invalid_chars, fn {c, line} ->
            "[line #{line}] Error: Unexpected character #{c}"
          end)
          |> Enum.join("\n")

        assert capture_io(:stderr, fn ->
                 scanner = Scanner.scan(scanner)
                 assert scanner.tokens == tokens
                 assert scanner.has_errors == length(invalid_chars) > 0
               end)
               |> String.trim() == expected_stderr
      end
    end

    property "with operators" do
      check all input <- StreamData.list_of(token_or_operator(), min_length: 1) do
        {scanner, tokens} = generate_scanner_and_expected_tokens(input)

        scanner = Scanner.scan(scanner)
        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "with comments" do
      check all input <-
                  StreamData.list_of(
                    StreamData.one_of([token_or_operator(), comment(), comment_with_newline()]),
                    min_length: 1
                  ) do
        {scanner, tokens} = generate_scanner_and_expected_tokens(input)

        scanner = Scanner.scan(scanner)
        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "'nonsense' valid lox content" do
      check all input <- lox_content() do
        {scanner, tokens} = generate_scanner_and_expected_tokens(input)

        # silence error output
        capture_io(:stderr, fn ->
          scanner = Scanner.scan(scanner)
          assert scanner.tokens == tokens
        end)
      end
    end
  end

  defp generate_scanner_and_expected_tokens(input) do
    {input, tokens} = Enum.unzip(input)
    input = Enum.join(input)
    tokens = finalize_tokens(tokens)

    scanner = Scanner.new(input)
    {scanner, tokens}
  end
end
