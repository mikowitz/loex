defmodule Loex.Expr do
  @moduledoc false

  @exprs [
    Binary: [:left, :operator, :right],
    Grouping: [:expression],
    Literal: [:value],
    Unary: [:operator, :right],
    Variable: [:name]
  ]

  for {name, fields} <- @exprs do
    params = Enum.map(fields, &{&1, [], Elixir})

    struct_fields = Enum.map(params, fn {name, _, _} = param -> {name, param} end)

    contents =
      quote do
        defstruct unquote(fields)

        def new(unquote_splicing(params)) do
          %__MODULE__{unquote_splicing(struct_fields)}
        end

        def accept(%__MODULE__{} = expr, visitor) do
          visitor.__struct__.visit(visitor, expr)
        end
      end

    name = Module.concat(__MODULE__, name)

    Module.create(name, contents, Macro.Env.location(__ENV__))
  end
end
