defmodule Loex.CLI do
  @moduledoc """
  Primary entrypoint for the `loex` executable
  """

  @doc false
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
        IO.puts("")
        System.stop(0)

      {:error, error} ->
        IO.puts(error)
        System.stop(65)

      data ->
        data |> String.trim() |> IO.puts()
        run_repl()
    end
  end

  defp run_file(filename) do
    case File.read(filename) do
      {:ok, contents} ->
        IO.puts(contents)

      {:error, error} ->
        IO.puts(:stderr, "Error reading #{filename}: #{error}")
        System.stop(65)
    end
  end
end
