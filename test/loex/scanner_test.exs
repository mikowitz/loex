defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  import ExUnitProperties

  import LoexTest.Support.Generators
  import LoexTest.Support.TestCaseHelpers

  alias Loex.Scanner
  alias Loex.Token

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
      check all input <- token() do
        {input, tokens, _errors} = prepare_tokens([input])
        scanner = Scanner.new(input)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "with a single line of single character tokens" do
      check all input <- StreamData.list_of(token(), min_length: 1) do
        {input, tokens, _errors} = prepare_tokens(input)
        scanner = Scanner.new(input)
        scanner = Scanner.scan(scanner)

        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "with invalid characters" do
      check all input <-
                  StreamData.list_of(StreamData.one_of([token(), invalid_char(), whitespace()]),
                    min_length: 1
                  ) do
        {input, tokens, errors} = prepare_tokens(input)
        scanner = Scanner.new(input)

        expected_stderr =
          Enum.map_join(errors, "\n", fn {c, line} ->
            "[line #{line}] Error: Unexpected character #{c}"
          end)

        assert capture_io(:stderr, fn ->
                 scanner = Scanner.scan(scanner)
                 assert scanner.tokens == tokens
                 assert scanner.has_errors == !Enum.empty?(errors)
               end)
               |> String.trim() == expected_stderr
      end
    end

    property "with operators" do
      check all input <- StreamData.list_of(token_or_operator(), min_length: 1) do
        {input, tokens, _errors} = prepare_tokens(input)
        scanner = Scanner.new(input)

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
        {input, tokens, _errors} = prepare_tokens(input)

        scanner = Scanner.new(input)
        scanner = Scanner.scan(scanner)
        assert scanner.tokens == tokens
        refute scanner.has_errors
      end
    end

    property "'nonsense' valid lox content" do
      check all input <- lox_content() do
        {input, tokens, _errors} = prepare_tokens(input)
        scanner = Scanner.new(input)

        capture_io(:stderr, fn ->
          scanner = Scanner.scan(scanner)
          assert scanner.tokens == tokens
        end)
      end
    end

    test "a string that starts in a comment" do
      input =
        """
        // "hello 
        !"
        """
        |> String.trim()

      scanner = Scanner.new(input)

      assert capture_io(:stderr, fn ->
               scanner = Scanner.scan(scanner)

               assert scanner.tokens == [
                        %Token{Token.bang() | line: 2},
                        %Token{Token.eof() | line: 2}
                      ]

               assert scanner.has_errors
             end) == """
             [line 2] Error: Unterminated string
             """
    end

    test "a multiline string" do
      input =
        """
        "hello
        this is a
        test" == "ok"
        """
        |> String.trim()

      scanner = Scanner.new(input)

      scanner = Scanner.scan(scanner)

      assert scanner.tokens == [
               %Token{Token.string("hello\nthis is a\ntest") | line: 1},
               %Token{Token.equal_equal() | line: 3},
               %Token{Token.string("ok") | line: 3},
               %Token{Token.eof() | line: 3}
             ]

      refute scanner.has_errors
    end

    test "a very large number" do
      input = "234728233234.23434343234."

      scanner = Scanner.new(input)

      scanner = Scanner.scan(scanner)

      assert scanner.tokens == [
               %Token{
                 type: :NUMBER,
                 line: 1,
                 lexeme: "234728233234.23434343234",
                 literal: 234_728_233_234.23434343234
               },
               %Token{type: :DOT, line: 1, lexeme: ".", literal: nil},
               %Token{Token.eof() | line: 1}
             ]

      refute scanner.has_errors
    end
  end
end
