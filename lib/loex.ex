defmodule Loex do
  @moduledoc """
  An Elixir implementation of the Lox programming language from 
  [craftinginterpreters.com]

  [craftinginterpreters.com]: https://craftinginterpreters.com
  """

  @doc false
  @spec error(integer(), String.t()) :: :ok
  def error(line, message) do
    IO.puts(
      :stderr,
      "[line #{line}] Error: #{message}"
    )
  end
end
