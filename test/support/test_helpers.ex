defmodule Loex.Test.Support.TestHelpers do
  use ExUnitProperties
  import StreamData

  def generate_input_and_expected_output(generator) do
    gen all tokens <- list_of(generator, min_length: 1) do
      {lexemes, tokens} = Enum.unzip(tokens)
      {Enum.join(lexemes), tokens}
    end
  end
end
