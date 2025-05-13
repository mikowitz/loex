defmodule Loex.CLI do
  alias Loex.Scanner

  def main(args) do
    case args do
      [] ->
        run_repl()

      [filename] ->
        run_file(filename)

      _ ->
        IO.puts(:stderr, "Usage: loex [script]")
        System.stop(64)
    end
  end

  defp run_repl do
    IO.write("> ")

    case IO.read(:line) do
      :eof ->
        System.stop(0)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading from stdin: #{reason}")
        System.stop(65)

      data ->
        data |> String.trim() |> run()
        run_repl()
    end
  end

  defp run_file(filename) do
    case File.read(filename) do
      {:ok, contents} ->
        run(contents)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading file: #{reason}")
        System.stop(65)
    end
  end

  defp run(contents) do
    scanner = Scanner.new(contents)
    scanner = Scanner.scan(scanner)

    for token <- scanner.tokens do
      IO.inspect(token)
    end
  end
end
