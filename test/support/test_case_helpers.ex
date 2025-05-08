defmodule LoexTest.Support.TestCaseHelpers do
  alias Loex.Token

  def finalize_tokens(tokens) do
    tokens
    |> Kernel.++([Token.eof()])
    |> add_line_numbers()
    |> handle_comments()
    |> correct_operators()
    |> Enum.filter(&is_struct(&1, Token))
  end

  ## ADD_LINE_NUMBERS ##

  def add_line_numbers([]), do: []
  def add_line_numbers(tokens), do: add_line_numbers(tokens, 1, [])

  def add_line_numbers([], _, acc), do: Enum.reverse(acc)

  def add_line_numbers([%Token{} = token | rest], line_number, acc) do
    add_line_numbers(rest, line_number, [%Token{token | line: line_number} | acc])
  end

  def add_line_numbers([:comment_with_newline | rest], line_number, acc) do
    add_line_numbers(rest, line_number + 1, [{:comment_with_newline, line_number} | acc])
  end

  def add_line_numbers([:newline | rest], line_number, acc) do
    add_line_numbers(rest, line_number + 1, [{:newline, line_number} | acc])
  end

  def add_line_numbers([x | rest], line_number, acc) do
    add_line_numbers(rest, line_number, [{x, line_number} | acc])
  end

  ## HANDLE_COMMENTS ##

  def handle_comments([]), do: []
  def handle_comments(tokens), do: handle_comments(tokens, [])

  def handle_comments([], acc), do: Enum.reverse(acc)

  def handle_comments([%Token{type: :SLASH, line: line}, %Token{type: :SLASH} | rest], acc) do
    handle_comments([{:comment, line} | rest], acc)
  end

  def handle_comments([%Token{type: :SLASH}, {:comment, _} = comment | rest], acc) do
    handle_comments([comment | rest], acc)
  end

  def handle_comments([%Token{type: :SLASH}, {:comment_with_newline, _} = comment | rest], acc) do
    handle_comments([comment | rest], acc)
  end

  def handle_comments([{:comment, _} | rest], acc) do
    rest =
      Enum.drop_while(rest, fn
        %Token{type: type} -> type != :EOF
        {:comment_with_newline, _} -> false
        {:newline, _} -> false
        _ -> true
      end)

    handle_comments(rest, acc)
  end

  def handle_comments([t | rest], acc), do: handle_comments(rest, [t | acc])

  ## CORRECT_OPERATORS ##

  def correct_operators([]), do: []
  def correct_operators(tokens), do: correct_operators(tokens, [])

  def correct_operators([], acc), do: Enum.reverse(acc)
  def correct_operators([t], acc), do: Enum.reverse([t | acc])

  def correct_operators([%Token{type: type} = t | [t2 | rest] = tail], acc)
      when type in ~w(BANG EQUAL LESS GREATER)a do
    case t2 do
      %Token{type: :EQUAL} ->
        correct_operators(rest, [extend_operator(t) | acc])

      %Token{type: :EQUAL_EQUAL} ->
        correct_operators([%Token{Token.equal() | line: t2.line} | rest], [
          extend_operator(t) | acc
        ])

      _ ->
        correct_operators(tail, [t | acc])
    end
  end

  def correct_operators([a | rest], acc) do
    correct_operators(rest, [a | acc])
  end

  defp extend_operator(%Token{type: :BANG} = token),
    do: %Token{token | type: :BANG_EQUAL, lexeme: "!="}

  defp extend_operator(%Token{type: :EQUAL} = token),
    do: %Token{token | type: :EQUAL_EQUAL, lexeme: "=="}

  defp extend_operator(%Token{type: :LESS} = token),
    do: %Token{token | type: :LESS_EQUAL, lexeme: "<="}

  defp extend_operator(%Token{type: :GREATER} = token),
    do: %Token{token | type: :GREATER_EQUAL, lexeme: ">="}
end
