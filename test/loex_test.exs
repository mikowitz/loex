defmodule LoexTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Loex

  describe "error/2" do
    test "logging an error to stderr" do
      actual_stderr =
        capture_io(:stderr, fn ->
          Loex.error(17, "this is a problem")
        end)

      assert actual_stderr =~ "[line 17] Error: this is a problem"
    end
  end
end
