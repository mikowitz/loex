defmodule Loex.CLI do
  @moduledoc """
  The primary entrypoint for interacting with the Loex interpreter.
  """

  alias Loex.Environment
  alias Loex.{Parser, Scanner, Statement}

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

  defp run_repl(env \\ %Environment{}) do
    IO.write("> ")

    case IO.read(:line) do
      :eof ->
        System.stop(0)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading from stdin: #{reason}")
        System.stop(65)

      data ->
        env = data |> String.trim() |> run(env)
        run_repl(env)
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

  defp run(contents, env \\ %Environment{}) do
    scanner = Scanner.new(contents)
    scanner = Scanner.scan(scanner)

    parser = Parser.new(scanner.tokens)
    parser = Parser.parse(parser)

    if !parser.has_errors && !Enum.empty?(parser.program) do
      Enum.reduce(parser.program, env, fn statement, env ->
        {_value, env} = Statement.interpret(statement, env)
        env
      end)
    else
      env
    end
  end
end
