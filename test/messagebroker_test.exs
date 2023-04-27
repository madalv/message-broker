defmodule MessagebrokerTest do
  use ExUnit.Case
  doctest Messagebroker

  test "greets the world" do
    assert Messagebroker.hello() == :world
  end
end
