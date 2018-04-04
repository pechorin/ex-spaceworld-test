defmodule SpaceworldTest do
  use ExUnit.Case
  doctest Spaceworld

  test "greets the world" do
    assert Spaceworld.hello() == :world
  end
end
