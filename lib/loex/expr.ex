defmodule Loex.Expr do
  @moduledoc false

  def evaluate(expr) do
    case expr.__struct__.evaluate(expr) do
      {:ok, result} -> result
      {:error, _error} -> :error
    end
  end
end
