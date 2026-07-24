defmodule Loex.EnvironmentTest do
  use ExUnit.Case, async: true

  alias Loex.{Environment, Token}

  describe "define" do
    test "adds a new value to the environment" do
      env = Environment.new()
      env = Environment.define(env, "foo", "bar")
      assert env.values == %{"foo" => "bar"}
    end

    test "overwrites an existing value" do
      env = Environment.new()
      env = Environment.define(env, "foo", "bar")
      assert env.values == %{"foo" => "bar"}

      env = Environment.define(env, "foo", "baz")
      assert env.values == %{"foo" => "baz"}
    end
  end

  describe "assign" do
    test "updates an existing value" do
      env = Environment.new() |> Environment.define("foo", "bar")
      {:ok, env} = Environment.assign(env, %Token{lexeme: "foo"}, "baz")
      assert env.values == %{"foo" => "baz"}
    end

    test "errors if value does not exist" do
      env = Environment.new() |> Environment.define("foo", "bar")
      {:error, message} = Environment.assign(env, %Token{lexeme: "foy"}, "baz")
      assert message == "Undefined variable `foy`."
    end

    test "updates in a nested enclosing environment" do
      env = %Environment{
        enclosing: %Environment{
          enclosing: %Environment{
            values: %{"foo" => "bar"}
          }
        }
      }

      {:ok, env} = Environment.assign(env, %Token{lexeme: "foo"}, "baz")

      assert env == %Environment{
               enclosing: %Environment{
                 enclosing: %Environment{
                   values: %{"foo" => "baz"}
                 }
               }
             }
    end
  end

  describe "get" do
    test "fetches from environment" do
      env = Environment.new() |> Environment.define("foo", "bar")

      {:ok, value} = Environment.get(env, %Token{lexeme: "foo"})
      assert value == "bar"
    end

    test "fetches from enclosing environment" do
      env = %Environment{
        enclosing: %Environment{
          enclosing: %Environment{
            values: %{"foo" => "bar"}
          }
        }
      }

      {:ok, value} = Environment.get(env, %Token{lexeme: "foo"})
      assert value == "bar"
    end

    test "error if doesn't exist" do
      env = %Environment{
        enclosing: %Environment{
          enclosing: %Environment{
            values: %{"foo" => "bar"}
          }
        }
      }

      {:error, message} = Environment.get(env, %Token{lexeme: "foy"})
      assert message == "Undefined variable `foy`."
    end
  end
end
