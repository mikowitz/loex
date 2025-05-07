defmodule Loex do
  def error(line, message) do
    IO.puts(
      :stderr,
      "[line #{line}] Error: #{message}"
    )
  end
end
