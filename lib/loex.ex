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
      IO.ANSI.format(
        [
          :red,
          "[line #{line}] Error: #{message}"
        ],
        Application.get_env(:loex, :color_output, true)
      )
    )
  end
end
