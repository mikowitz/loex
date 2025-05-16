defmodule Loex.Expr.Variable do
  @moduledoc false

  defstruct [:name]

  def new(name), do: %__MODULE__{name: name}

  defimpl Loex.Expr do
    def to_string(%@for{name: name}), do: "(variable \"#{name}\")"

    def evaluate(%@for{name: _name}), do: nil
  end
end
