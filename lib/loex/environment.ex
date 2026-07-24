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

  @spec get(__MODULE__.t(), Loex.Token.t()) :: {:ok, any()} | {:error, bitstring()}
  def get(%__MODULE__{values: values}, name) do
    case name.lexeme in Map.keys(values) do
      true -> {:ok, Map.get(values, name.lexeme)}
      false -> {:error, "Undefined variable `#{name.lexeme}`."}
    end
  end

  @spec assign(__MODULE__.t(), Loex.Token.t(), any()) ::
          {:ok, __MODULE__.t()} | {:error, bitstring()}
  def assign(%__MODULE__{values: values} = env, name, value) do
    case name.lexeme in Map.keys(values) do
      true ->
        env = %{env | values: Map.put(values, name.lexeme, value)}
        {:ok, env}

      false ->
        {:error, "Undefined variable `#{name.lexeme}`."}
    end
  end
end
