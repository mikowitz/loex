defmodule Loex do
  def error(line, message) do
    IO.puts(
      :stderr,
      IO.ANSI.format([:red, "[line #{line}] Error: #{message}"])
    )
  end
end
