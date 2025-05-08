defmodule LoexTest.Support.TestCaseHelpers do
  @moduledoc false

  alias Loex.Token

  use Loex.Constants

  def prepare_tokens(input) do
    input
    # NOTE: double slashes turning into comments gets weird, so let's skip it
    # and numbers and identifiers getting mashed together
    |> Enum.map(fn
      {"/", %Token{type: :SLASH}} = t -> [t, {" ", :space}]
      {_, %Token{type: :NUMBER}} = t -> [t, {" ", :space}]
      {_, %Token{type: :IDENTIFIER}} = t -> [t, {" ", :space}]
      {_, %Token{lexeme: lex}} = t when lex in @reserved_words -> [t, {" ", :space}]
      t -> t
    end)
    |> List.flatten()
    |> prepare_tokens("", [], [], 1)
  end

  ## PREPARE_TOKENS ##

  @op_type ~w(BANG EQUAL LESS GREATER)a

  defp prepare_tokens([], input, tokens, errors, line) do
    eof = %Token{Token.eof() | line: line}
    {input, Enum.reverse([eof | tokens]), Enum.reverse(errors)}
  end

  defp prepare_tokens([{str, %Token{type: :STRING} = t} | rest], input, tokens, errors, line) do
    token = %Token{t | line: line}
    line_delta = to_charlist(str) |> Enum.count(&(&1 == ?\n))
    prepare_tokens(rest, input <> str, [token | tokens], errors, line + line_delta)
  end

  defp prepare_tokens([{_, %Token{type: t}} = token | rest], input, tokens, errors, line)
       when t in @op_type do
    {op_lex, op_token, rest} = handle_operator(token, rest)
    op_token = %Token{op_token | line: line}
    prepare_tokens(rest, input <> op_lex, [op_token | tokens], errors, line)
  end

  defp prepare_tokens([{lex, %Token{} = tok} | rest], input, tokens, errors, line) do
    tok = %Token{tok | line: line}
    prepare_tokens(rest, input <> to_string(lex), [tok | tokens], errors, line)
  end

  defp prepare_tokens([{lex, :invalid} | rest], input, tokens, errors, line) do
    errors = [{lex, line} | errors]
    prepare_tokens(rest, input <> lex, tokens, errors, line)
  end

  defp prepare_tokens([{lex, t} | rest], input, tokens, errors, line)
       when t in ~w(newline comment_with_newline)a do
    prepare_tokens(rest, input <> lex, tokens, errors, line + 1)
  end

  defp prepare_tokens([{lex, :comment} | rest], input, tokens, errors, line) do
    rest = drop_until_newline(rest)
    prepare_tokens(rest, input <> lex, tokens, errors, line)
  end

  defp prepare_tokens([{lex, _} | rest], input, tokens, errors, line) do
    prepare_tokens(rest, input <> lex, tokens, errors, line)
  end

  ## DROP_UNTIL_NEWLINE ##

  defp drop_until_newline([]), do: []
  defp drop_until_newline([{_, :newline} | _] = rest), do: rest
  defp drop_until_newline([{_, :comment_with_newline} | _] = rest), do: rest
  # NOTE: strings starting in a comment are tricky, so move any starting strings to a new line
  # this case is handled in a specific test
  defp drop_until_newline([{_, %Token{type: :STRING}} | _] = rest), do: [{"\n", :newline} | rest]
  defp drop_until_newline([_ | rest]), do: drop_until_newline(rest)

  ## HANDLE_OPERATOR ##

  defp handle_operator({lex, tok}, [{"=", %Token{type: :EQUAL}} | rest]) do
    {lex <> "=", extend_operator(tok), rest}
  end

  defp handle_operator({lex, tok}, [{"==", %Token{type: :EQUAL_EQUAL}} | rest]) do
    {lex <> "=", extend_operator(tok), [{"=", Token.equal()} | rest]}
  end

  defp handle_operator({lex, tok}, rest) do
    {lex, tok, rest}
  end

  ## EXTEND_OPERATOR ##

  defp extend_operator(%Token{type: :BANG}), do: Token.bang_equal()
  defp extend_operator(%Token{type: :EQUAL}), do: Token.equal_equal()
  defp extend_operator(%Token{type: :LESS}), do: Token.less_equal()
  defp extend_operator(%Token{type: :GREATER}), do: Token.greater_equal()
end
