defmodule Loex.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @reserved_words ~w(and class else false for fun if nil or print return super this true var while)
    end
  end
end
