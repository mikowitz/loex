defmodule Loex.ScannerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Loex.Scanner

  describe "scan" do
    test "punctuators" do
      source = File.read!("./test/support/testdata/operators.lox")

      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, & &1.type) == [
               :LEFT_PAREN,
               :RIGHT_PAREN,
               :LEFT_BRACE,
               :RIGHT_BRACE,
               :SEMICOLON,
               :COMMA,
               :PLUS,
               :MINUS,
               :STAR,
               :BANG_EQUAL,
               :EQUAL_EQUAL,
               :LESS_EQUAL,
               :GREATER_EQUAL,
               :BANG_EQUAL,
               :LESS,
               :GREATER,
               :SLASH,
               :DOT,
               :LEFT_PAREN,
               :LEFT_PAREN,
               :RIGHT_PAREN,
               :RIGHT_PAREN,
               :LEFT_BRACE,
               :RIGHT_BRACE,
               :BANG,
               :STAR,
               :PLUS,
               :MINUS,
               :SLASH,
               :EQUAL,
               :LESS,
               :GREATER,
               :LESS_EQUAL,
               :EQUAL_EQUAL,
               :EOF
             ]
    end

    test "strings" do
      source = File.read!("./test/support/testdata/strings.lox")
      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, &{&1.type, &1.literal, &1.lexeme}) == [
               {:STRING, "", "\"\""},
               {:STRING, "string", "\"string\""},
               {:EOF, nil, ""}
             ]
    end

    test "keywords" do
      source = File.read!("./test/support/testdata/keywords.lox")
      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, & &1.type) == ~w(
        AND CLASS ELSE FALSE FOR FUN IF NIL OR RETURN SUPER THIS TRUE VAR WHILE EOF
      )a
    end

    test "identifiers" do
      source = File.read!("./test/support/testdata/identifiers.lox")
      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, &{&1.type, &1.lexeme}) == [
               {:IDENTIFIER, "andy"},
               {:IDENTIFIER, "formless"},
               {:IDENTIFIER, "fo"},
               {:IDENTIFIER, "_"},
               {:IDENTIFIER, "_123"},
               {:IDENTIFIER, "_abc"},
               {:IDENTIFIER, "ab123"},
               {:IDENTIFIER, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_"},
               {:IDENTIFIER, "ABc1234"},
               {:EOF, ""}
             ]
    end

    test "numbers" do
      source = File.read!("./test/support/testdata/numbers.lox")
      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, &{&1.type, &1.literal, &1.lexeme}) == [
               {:NUMBER, 123.0, "123"},
               {:NUMBER, 123.456, "123.456"},
               {:DOT, nil, "."},
               {:NUMBER, 456.0, "456"},
               {:NUMBER, 234.0, "234"},
               {:DOT, nil, "."},
               {:EOF, nil, ""}
             ]
    end

    test "whitespace" do
      source = File.read!("./test/support/testdata/whitespace.lox")
      scanner = Scanner.new(source) |> Scanner.scan()

      assert Enum.map(scanner.tokens, &{&1.type, &1.lexeme}) == [
               {:IDENTIFIER, "space"},
               {:IDENTIFIER, "tabs"},
               {:IDENTIFIER, "newlines"},
               {:IDENTIFIER, "end"},
               {:EOF, ""}
             ]
    end
  end

  describe "error states" do
    test "unterminated string" do
      source = File.read!("./test/support/testdata/string/unterminated.lox")

      output =
        capture_io(:stderr, fn ->
          scanner = Scanner.new(source) |> Scanner.scan()
          assert scanner.runtime.had_error
        end)

      assert output =~ "[line 2] Error: Unterminated string."
    end

    test "unexpected character" do
      source = File.read!("./test/support/testdata/unexpected_character.lox")

      output =
        capture_io(:stderr, fn ->
          scanner = Scanner.new(source) |> Scanner.scan()
          assert scanner.runtime.had_error
        end)

      assert output =~ "[line 1] Error: Unexpected character: `|`."
    end
  end
end
