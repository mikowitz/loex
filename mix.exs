defmodule Loex.MixProject do
  use Mix.Project

  def project do
    [
      app: :loex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: [main_module: Loex.CLI],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.12", only: [:test], runtime: false},
      {:ex_doc, "~> 0.37.3", runtime: false},
      {:mix_test_watch, "~> 1.2.0", only: [:test], runtime: false},
      {:stream_data, "~> 1.2.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
