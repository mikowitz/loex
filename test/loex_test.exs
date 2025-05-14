defmodule LoexTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "error/2" do
    test "writes the correct error to stderr" do
      output =
        capture_io(:stderr, fn ->
          Loex.error(3, "it doesn't work")
        end)

      assert output =~ "[line 3] Error: it doesn't work"
    end
  end
end
