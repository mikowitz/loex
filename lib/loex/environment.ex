defmodule Loex.Environment do
  @moduledoc "Stores shared state during interpretation"

  defstruct values: %{}

  @type t :: %__MODULE__{
          values: map()
        }

  @spec define(__MODULE__.t(), bitstring(), any()) :: __MODULE__.t()
  def define(%__MODULE__{values: values} = env, name, value) do
    %{env | values: Map.put(values, name, value)}
  end

  @spec get(__MODULE__.t(), Loex.Token.t()) :: any()
  def get(%__MODULE__{values: values}, name) do
    case name.lexeme in Map.keys(values) do
      true -> {:ok, Map.get(values, name.lexeme)}
      false -> {:error, "Undefined variable `#{name.lexeme}`."}
    end
  end
end
