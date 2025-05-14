defmodule Loex do
  @moduledoc """
  An Elixir interpreter for the Lox programming language, 
  as defined in craftinginterpreters.com
  """

  def error(line, message) do
    IO.puts(
      :stderr,
      IO.ANSI.format([:red, "[line #{line}] Error: #{message}"])
    )
  end
end
