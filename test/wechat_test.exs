defmodule WechatTest do
  use ExUnit.Case
  doctest Wechat

  test "greets the world" do
    assert Wechat.hello() == :world
  end
end
