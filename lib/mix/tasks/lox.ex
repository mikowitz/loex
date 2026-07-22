defmodule Mix.Tasks.Lox do
  @moduledoc "Run the lox interpreter: `mix lox [script]`"
  use Mix.Task

  @shortdoc "Runs the lox interpreter."
  def run(args) do
    Loex.main(args)
  end
end
