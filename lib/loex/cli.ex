defmodule Loex.CLI do
  def main(args) do
    case args do
      [] ->
        run_repl()

      [filename] ->
        run_file(filename)

      [_ | _] ->
        IO.puts(:stderr, "Usage: loex [script]")
        System.stop(64)
    end
  end

  defp run_repl do
    IO.write("lox> ")

    case IO.read(:line) do
      :eof ->
        System.stop(0)

      {:error, error} ->
        IO.puts(:stderr, "Error: #{error}")
        System.stop(65)

      data ->
        run(data)
        run_repl()
    end
  end

  defp run_file(filename) do
    case File.read(filename) do
      {:ok, contents} ->
        run(contents)

      {:error, error} ->
        IO.puts(:stderr, "Error reading file #{filename}: #{inspect(error)}")
        System.stop(66)
    end
  end

  defp run(input) do
    input |> String.trim() |> IO.puts()
  end
end
