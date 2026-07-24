defmodule Loex do
  @moduledoc """
  Main entrypoint into the Loex interpreter
  """

  defstruct had_error: false

  @type t :: %__MODULE__{
          had_error: boolean()
        }

  def main(args) do
    runtime = %__MODULE__{}

    case args do
      [filename] ->
        run_file(filename, runtime)

      [] ->
        run_repl(runtime)

      _ ->
        IO.puts(:stderr, "Usage: mix lox [script]")
        System.stop(64)
    end
  end

  defp run_file(filename, runtime) do
    {:ok, file} = File.read(filename)
    runtime = run(file, runtime)
    if runtime.had_error, do: System.stop(65)
  end

  defp run_repl(runtime) do
    IO.write("> ")

    case IO.read(:line) do
      :EOF ->
        System.stop(0)

      line ->
        runtime = String.trim(line) |> run(runtime)
        runtime = %{runtime | had_error: false}
        run_repl(runtime)
    end
  end

  defp run(data, runtime) do
    scanner = Loex.Scanner.new(data, runtime)
    scanner = Loex.Scanner.scan(scanner)

    parser = Loex.Parser.new(scanner.tokens, scanner.runtime)
    {expr, parser} = Loex.Parser.parse(parser)

    if !parser.runtime.had_error do
      printer = %Loex.AstPrinter{}
      IO.puts(Loex.AstPrinter.print(printer, expr))
    end

    parser.runtime
  end

  def error(%__MODULE__{} = runtime, %Loex.Token{} = token, message) do
    case token.type do
      :EOF -> report(runtime, token.loc, "at end", message)
      _ -> report(runtime, token.loc, "at `#{token.lexeme}`", message)
    end
  end

  def error(%__MODULE__{} = runtime, loc, message) do
    report(runtime, loc, "", message)
  end

  defp report(%__MODULE__{} = runtime, loc, where, message) do
    where =
      case where do
        "" -> ""
        _ -> " #{where}"
      end

    IO.puts(
      :stderr,
      "[line #{loc}] Error#{where}: #{message}"
    )

    %{runtime | had_error: true}
  end
end
