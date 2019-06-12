defmodule LoggerEtsBackendTest do
  use ExUnit.Case
  doctest LoggerEtsBackend

  test "greets the world" do
    assert LoggerEtsBackend.hello() == :world
  end
end
