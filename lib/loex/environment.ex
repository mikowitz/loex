defmodule Loex.Environment do
  defstruct values: %{}, outer: nil

  @moduledoc """
  Models the environment state of a running Lox program
  """

  def put(%__MODULE__{values: values} = env, key, value) do
    %__MODULE__{env | values: Map.put(values, key, value)}
  end

  def get(%__MODULE__{values: values, outer: outer}, key, line) do
    cond do
      key in Map.keys(values) ->
        Map.get(values, key)

      is_struct(outer, __MODULE__) ->
        __MODULE__.get(outer, key, line)

      true ->
        Loex.error(line, "Undefined variable: `#{key}'")
        nil
    end
  end
end
