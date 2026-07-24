defmodule Loex.Environment do
  @moduledoc "Stores shared state during interpretation"

  defstruct [:enclosing, values: %{}]

  @type t :: %__MODULE__{
          values: map(),
          enclosing: __MODULE__.t()
        }

  def new(enclosing \\ nil), do: %__MODULE__{enclosing: enclosing}

  @spec define(__MODULE__.t(), bitstring(), any()) :: __MODULE__.t()
  def define(%__MODULE__{values: values} = env, name, value) do
    %{env | values: Map.put(values, name, value)}
  end

  @spec get(__MODULE__.t(), Loex.Token.t()) :: {:ok, any()} | {:error, bitstring()}
  def get(%__MODULE__{values: values, enclosing: enclosing}, name) do
    case name.lexeme in Map.keys(values) do
      true ->
        {:ok, Map.get(values, name.lexeme)}

      false ->
        case enclosing do
          nil -> {:error, "Undefined variable `#{name.lexeme}`."}
          enc -> get(enc, name)
        end
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
        assign_in_enclosing(env, name, value)
    end
  end

  defp assign_in_enclosing(%__MODULE__{enclosing: enclosing} = env, name, value) do
    case enclosing do
      nil ->
        {:error, "Undefined variable `#{name.lexeme}`."}

      enc ->
        case assign(enc, name, value) do
          {:ok, enc} -> {:ok, %{env | enclosing: enc}}
          {:error, _} = error -> error
        end
    end
  end
end
