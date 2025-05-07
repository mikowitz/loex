defmodule Loex do
  @doc false
  @spec report_error(integer(), String.t()) :: :ok
  def report_error(line, message) do
    IO.puts(
      :stderr,
      "[line #{line}] Error: #{message}"
    )
  end
end
