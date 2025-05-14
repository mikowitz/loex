defmodule Loex.Test.Support.Generators do
  @moduledoc false

  import StreamData
  use ExUnitProperties

  alias Loex.Token

  def unambiguous_token do
    %{
      LEFT_PAREN: "(",
      RIGHT_PAREN: ")",
      LEFT_BRACE: "{",
      RIGHT_BRACE: "}",
      COMMA: ",",
      DOT: ".",
      MINUS: "-",
      PLUS: "+",
      SEMICOLON: ";",
      STAR: "*",
      SLASH: "/"
    }
    |> Enum.map(fn {type, lex} ->
      constant({lex, Token.new(type, lex, nil, 1)})
    end)
    |> one_of()
  end

  def invalid_character do
    ~w(@ # $ % ^ &)
    |> Enum.map(fn c -> constant({c, {:invalid_char, c}}) end)
    |> one_of()
  end

  def operator do
    %{
      BANG_EQUAL: "!=",
      BANG: "!",
      EQUAL_EQUAL: "==",
      EQUAL: "=",
      GREATER_EQUAL: ">=",
      GREATER: ">",
      LESS_EQUAL: "<=",
      LESS: "<"
    }
    |> Enum.map(fn {type, lex} ->
      constant({lex, Token.new(type, lex, nil, 1)})
    end)
    |> one_of()
  end

  def single_line_comment do
    string(:ascii)
    |> map(fn comment ->
      {"// #{comment}\n", :comment}
    end)
  end

  def block_comment do
    list_of(string(:alphanumeric))
    |> map(fn ss ->
      comment = "/* " <> Enum.join(ss, "\n") <> " */"
      line_delta = String.codepoints(comment) |> Enum.count(&(&1 == "\n"))
      {"/* " <> Enum.join(ss, "\n") <> " */", {:block_comment, line_delta}}
    end)
  end

  def comment do
    one_of([
      single_line_comment(),
      block_comment()
    ])
  end

  def whitespace do
    [
      {" ", :space},
      {"\n", :newline},
      {"\t", :tab}
    ]
    |> Enum.map(&constant/1)
    |> one_of()
  end

  def string do
    string(Enum.concat([?a..?z, [?\n]]))
    |> map(fn s ->
      {~s["#{s}"], Token.new(:STRING, s, s, 1)}
    end)
  end

  def number do
    one_of([
      integer(0..999),
      float(min: 0.5, max: 999.5)
    ])
    |> map(fn n ->
      {to_string(n), Token.new(:NUMBER, to_string(n), n * 1.0, 1)}
    end)
  end

  @reserved_words ~w(and class else false for fun if nil or print return super this true var while)

  def reserved_word do
    @reserved_words
    |> Enum.map(fn word ->
      constant({
        word,
        Token.new(:"#{String.upcase(word)}", word, nil, 1)
      })
    end)
    |> one_of()
  end

  def identifier do
    string([?a..?z, ?A..?Z, ?1..?9, ?_], min_length: 1)
    |> filter(&(&1 not in @reserved_words))
    |> filter(fn <<s, _rest::binary>> -> s not in ?0..?9 end)
    |> map(fn id ->
      {id, Token.new(:IDENTIFIER, id, nil, 1)}
    end)
  end

  def token do
    one_of([
      unambiguous_token(),
      invalid_character(),
      operator(),
      comment(),
      whitespace(),
      string(),
      number(),
      identifier(),
      reserved_word()
    ])
  end
end
