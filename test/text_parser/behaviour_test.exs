defmodule TextParser.BehaviourTest do
  use ExUnit.Case, async: true

  alias TextParser.Tokens.{Tag, URL}

  defmodule TestParser do
    use TextParser

    def validate(%Tag{value: value} = tag) do
      if String.length(value) >= 10,
        do: {:error, "tag too long"},
        else: {:ok, tag}
    end

    def validate(token), do: {:ok, token}
  end

  describe "custom parser" do
    test "validates tokens according to custom rules" do
      result = TestParser.parse("Check out #tag")
      tags = TextParser.get(result, Tag)
      assert length(tags) == 1
      assert hd(tags).value == "#tag"

      result = TestParser.parse("Check out #verylongtag")
      assert TextParser.get(result, Tag) == []

      result = TestParser.parse("Check https://example.com #tag")
      urls = TextParser.get(result, URL)
      assert length(urls) == 1
      assert hd(urls).value == "https://example.com"
    end

    test "supports custom extractors" do
      result = TestParser.parse("Check out #tag", extract: [Tag])
      assert length(result.tokens) == 1
      assert hd(result.tokens).value == "#tag"
    end
  end
end
