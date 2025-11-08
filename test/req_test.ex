defmodule PhenomWeb.ErrorHTMLTest do
  use PhenomWeb.ConnCase, async: true

  test "no real requests are made" do
    assert_raise(RuntimeError, ~r/cannot find mock\/stub/, fn ->
      Req.get!("https://google.com")
    end)
  end
end
