import Config

config :loex, color_output: false

config :mix_test_watch,
  tasks: [
    "test",
    "credo --strict --all",
    "docs"
  ]
