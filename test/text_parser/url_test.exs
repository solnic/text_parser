defmodule TextParser.Tokens.URLTest do
  use ExUnit.Case, async: true

  alias TextParser.Tokens.URL

  describe "is_valid?/1" do
    test "validates URLs with http/https scheme" do
      assert URL.is_valid?("https://example.com")
      assert URL.is_valid?("http://example.com")
      assert URL.is_valid?("https://example.com/path")
      assert URL.is_valid?("https://example.com/path?param=value")
    end

    test "validates bare domains" do
      assert URL.is_valid?("example.com")
      assert URL.is_valid?("sub.example.com")
    end

    test "rejects invalid URLs" do
      refute URL.is_valid?("not a url")
      refute URL.is_valid?("http://")
      refute URL.is_valid?("https://")
      refute URL.is_valid?("example")
      refute URL.is_valid?("example.")
      refute URL.is_valid?("example.invalidtld")
      refute URL.is_valid?("foo...bar")
      refute URL.is_valid?("http://.com")
      refute URL.is_valid?("http://example")
    end

    test "rejects non-string input" do
      refute URL.is_valid?(nil)
      refute URL.is_valid?(123)
      refute URL.is_valid?(%{})
    end
  end
end
