defmodule Loex.Environment do
  defstruct values: %{}, outer: nil

  @moduledoc """
  Models the environment state of a running Lox program
  """

  def put(%__MODULE__{values: values} = env, key, value) do
    %__MODULE__{env | values: Map.put(values, key, value)}
  end

  def get(%__MODULE__{values: values}, key) do
    case key in Map.keys(values) do
      true ->
        Map.get(values, key)

      false ->
        Loex.error(1, "Undefined variable: `#{key}'")
        nil
    end
  end
end
