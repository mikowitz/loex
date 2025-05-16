defmodule Loex.Environment do
  @moduledoc """
  Models the environment state of a running Lox program
  """

  def put(values, key, value) do
    Map.put(values, key, value)
  end

  def get(values, key) do
    case key in Map.keys(values) do
      true ->
        Map.get(values, key)

      false ->
        raise "Undefined variable: `#{key}'"
    end
  end
end
