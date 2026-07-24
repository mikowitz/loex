defmodule Loex do
  @moduledoc """
  Main entrypoint into the Loex interpreter
  """

  defstruct had_error: false, had_runtime_error: false

  @type t :: %__MODULE__{
          had_error: boolean()
        }

  def main(args) do
    runtime = %__MODULE__{}
    interpreter = Loex.Interpreter.new(runtime)

    case args do
      [filename] ->
        run_file(filename, interpreter)

      [] ->
        run_repl(interpreter)

      _ ->
        IO.puts(:stderr, "Usage: mix lox [script]")
        System.stop(64)
    end
  end

  defp run_file(filename, interpreter) do
    {:ok, file} = File.read(filename)
    interpreter = run(file, interpreter)
    if interpreter.runtime.had_error, do: System.stop(65)
    if interpreter.runtime.had_runtime_error, do: System.stop(64)
  end

  defp run_repl(interpreter) do
    IO.write("> ")

    case IO.read(:line) do
      :EOF ->
        System.stop(0)

      line ->
        interpreter = String.trim(line) |> run(interpreter)
        runtime = %{interpreter.runtime | had_error: false, had_runtime_error: false}
        run_repl(%{interpreter | runtime: runtime})
    end
  end

  defp run(data, interpreter) do
    scanner = Loex.Scanner.new(data, interpreter.runtime)
    scanner = Loex.Scanner.scan(scanner)

    parser = Loex.Parser.new(scanner.tokens, scanner.runtime)
    {expr, parser} = Loex.Parser.parse(parser)

    case parser.runtime.had_error do
      true ->
        %{interpreter | runtime: parser.runtime}

      false ->
        interpreter = %{interpreter | runtime: parser.runtime}
        Loex.Interpreter.interpret(interpreter, expr)
    end
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

  def runtime_error(%__MODULE__{} = runtime, %Loex.Token{} = token, message) do
    IO.puts(
      :stderr,
      "#{message}\n[line #{token.loc}]"
    )

    %{runtime | had_runtime_error: true}
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
