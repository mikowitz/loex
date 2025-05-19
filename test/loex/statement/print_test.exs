defmodule Loex.Statement.PrintTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  use ExUnitProperties

  alias Loex.Expr.{Binary, Literal}
  alias Loex.Statement
  alias Loex.Statement.Print
  alias Loex.Token

  describe "interpret" do
    property "a print statement" do
      check all a <- float(min: 0.5, max: 999.5),
                b <- float(min: 0.5, max: 999.5) do
        statement =
          Print.new(Binary.new(Literal.new(a), Token.new(:PLUS, "+", nil, 1), Literal.new(b)))

        output =
          capture_io(fn ->
            Statement.interpret(statement)
          end)

        assert output =~ to_string(a + b)
      end
    end
  end
end
