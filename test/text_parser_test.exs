defmodule TextParserTest do
  use ExUnit.Case, async: true

  describe "parse/1" do
    test "extracts valid URLs from text" do
      text = "Check out https://example.com for more info"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      [url] = result.urls
      assert url.value == "https://example.com"
      assert url.position == {10, 29}
    end

    test "handles multiple URLs with punctuation" do
      text = "Check these: https://example.com, https://test.com!"
      result = TextParser.parse(text)

      assert length(result.urls) == 2
      [url1, url2] = result.urls
      assert url1.value == "https://example.com"
      assert url1.position == {13, 32}
      assert url2.value == "https://test.com"
      assert url2.position == {34, 50}
    end

    test "handles URLs with unicode characters" do
      text = "Cool link! 🔥 https://example.com"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      [url] = result.urls
      assert url.value == "https://example.com"
      assert url.position == {16, 35}
    end

    test "ignores invalid URLs" do
      text = "This is not...a.url and this.is.not..either and foo...bar is not"
      result = TextParser.parse(text)

      assert result.urls == []
    end

    test "extracts valid tags from text" do
      text = "Check out #elixir and #phoenix for more info"
      result = TextParser.parse(text)

      assert length(result.tags) == 2
      [tag1, tag2] = result.tags
      assert tag1.value == "#elixir"
      assert tag1.position == {10, 17}
      assert tag2.value == "#phoenix"
      assert tag2.position == {22, 30}
    end

    test "handles tags with underscores and numbers" do
      text = "Using #elixir_lang and #phoenix2 framework"
      result = TextParser.parse(text)

      assert length(result.tags) == 2
      [tag1, tag2] = result.tags
      assert tag1.value == "#elixir_lang"
      assert tag1.position == {6, 18}
      assert tag2.value == "#phoenix2"
      assert tag2.position == {23, 32}
    end

    test "ignores invalid tags" do
      text = "Invalid tags: #123 #. #! ## #"
      result = TextParser.parse(text)

      assert result.tags == []
    end

    test "allows tags with digits if they contain letters" do
      text = "Valid tags: #123foo #foo123 #123-abc"
      result = TextParser.parse(text)

      assert length(result.tags) == 1
      [tag] = result.tags
      assert tag.value == "#foo123"
      assert tag.position == {20, 27}
    end

    test "handles both URLs and tags in the same text" do
      text = "Check out https://elixir-lang.org #elixir #programming"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      assert length(result.tags) == 2

      [url] = result.urls
      assert url.value == "https://elixir-lang.org"
      assert url.position == {10, 33}

      [tag1, tag2] = result.tags
      assert tag1.value == "#elixir"
      assert tag1.position == {34, 41}
      assert tag2.value == "#programming"
      assert tag2.position == {42, 54}
    end

    test "handles tags with unicode characters" do
      text = "Cool tag! 🔥 #elixir"
      result = TextParser.parse(text)

      assert length(result.tags) == 1
      [tag] = result.tags
      assert tag.value == "#elixir"
      assert tag.position == {15, 22}
    end

    # Additional tests from bsky_test.exs scenarios
    test "handles multiple tags with exact byte positions" do
      text = "Check out #awesome #coding"
      result = TextParser.parse(text)

      assert length(result.tags) == 2
      [tag1, tag2] = result.tags
      assert tag1.value == "#awesome"
      assert tag1.position == {10, 18}
      assert tag2.value == "#coding"
      assert tag2.position == {19, 26}
    end

    test "handles tags with URLs and mentions with exact positions" do
      text = "Hey @friend.bsky.handle check https://example.com #awesome"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      [url] = result.urls
      assert url.value == "https://example.com"
      assert url.position == {30, 49}

      assert length(result.tags) == 1
      [tag] = result.tags
      assert tag.value == "#awesome"
      assert tag.position == {50, 58}
    end

    test "handles multiple tags at the end of text" do
      text = "Check these #awesome #coding"
      result = TextParser.parse(text)

      assert length(result.tags) == 2
      [tag1, tag2] = result.tags
      assert tag1.value == "#awesome"
      assert tag1.position == {12, 20}
      assert tag2.value == "#coding"
      assert tag2.position == {21, 28}
    end

    test "handles tags with trailing punctuation" do
      text = "Love #elixir! #phoenix, #programming."
      result = TextParser.parse(text)

      assert length(result.tags) == 3
      [tag1, tag2, tag3] = result.tags
      assert tag1.value == "#elixir"
      assert tag1.position == {5, 12}
      assert tag2.value == "#phoenix"
      assert tag2.position == {14, 22}
      assert tag3.value == "#programming"
      assert tag3.position == {24, 36}
    end

    test "handles tags with emoji between them" do
      text = "Cool! #elixir 🚀 #phoenix 🔥 #programming"
      result = TextParser.parse(text)

      assert length(result.tags) == 3
      [tag1, tag2, tag3] = result.tags
      assert tag1.value == "#elixir"
      assert tag1.position == {6, 13}
      assert tag2.value == "#phoenix"
      assert tag2.position == {19, 27}
      assert tag3.value == "#programming"
      assert tag3.position == {33, 45}
    end

    test "handles complex text with URLs, tags, and unicode" do
      text = "🌟 Check https://elixir-lang.org #elixir_lang 🚀 #phoenix #programming!"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      [url] = result.urls
      assert url.value == "https://elixir-lang.org"
      assert url.position == {11, 34}

      assert length(result.tags) == 3
      [tag1, tag2, tag3] = result.tags

      assert tag1.value == "#elixir_lang"
      assert tag1.position == {35, 47}
      assert tag2.value == "#phoenix"
      assert tag2.position == {53, 61}
      assert tag3.value == "#programming"
      assert tag3.position == {62, 74}
    end

    test "handles , and ! after a tag correctly" do
      text = "How about some #tags #right_here #hello, there! #123goo!"
      result = TextParser.parse(text)

      # #123goo is invalid - first char after # is digit
      assert length(result.tags) == 3
      [tag1, tag2, tag3] = result.tags

      assert tag1.value == "#tags"
      assert tag1.position == {15, 20}

      assert tag2.value == "#right_here"
      assert tag2.position == {21, 32}

      # Position excludes the comma, just like the value
      assert tag3.value == "#hello"
      # excludes the comma
      assert tag3.position == {33, 39}
    end

    test "handles emoji after a tag correctly" do
      text = "How about #hello🔥 #world!"
      result = TextParser.parse(text)

      # #123goo is invalid - first char after # is digit
      assert length(result.tags) == 2
      [tag1, tag2] = result.tags

      assert tag1.value == "#hello"
      assert tag1.position == {10, 16}

      assert tag2.value == "#world"
      assert tag2.position == {21, 27}
    end

    test "enforces tag length limit" do
      # 67 chars total
      long_tag = "#" <> String.duplicate("a", 66)
      text = "This tag is too long: #{long_tag}"
      result = TextParser.parse(text)

      assert result.tags == []
    end

    test "extracts valid mentions from text" do
      text = "Hey @user and @other.bsky.social for more info"
      result = TextParser.parse(text)

      assert length(result.mentions) == 2
      [mention1, mention2] = result.mentions
      assert mention1.value == "@user"
      assert mention1.position == {4, 9}
      assert mention2.value == "@other.bsky.social"
      assert mention2.position == {14, 32}
    end

    test "handles mentions with trailing punctuation" do
      text = "Hey @user! @other, and @third."
      result = TextParser.parse(text)

      assert length(result.mentions) == 3
      [mention1, mention2, mention3] = result.mentions
      assert mention1.value == "@user"
      assert mention1.position == {4, 9}
      assert mention2.value == "@other"
      assert mention2.position == {11, 17}
      assert mention3.value == "@third"
      assert mention3.position == {23, 29}
    end

    test "handles mentions with emoji" do
      text = "Hey @user🔥 and @other🚀!"
      result = TextParser.parse(text)

      assert length(result.mentions) == 2
      [mention1, mention2] = result.mentions
      assert mention1.value == "@user"
      assert mention1.position == {4, 9}
      assert mention2.value == "@other"
      assert mention2.position == {18, 24}
    end

    test "ignores invalid mentions" do
      text = "Invalid mentions: @ @. @! @@ @"
      result = TextParser.parse(text)

      assert result.mentions == []
    end

    test "handles mentions with dots and hyphens" do
      text = "Valid mentions: @user.name @other-handle @third_name"
      result = TextParser.parse(text)

      assert length(result.mentions) == 3
      [mention1, mention2, mention3] = result.mentions
      assert mention1.value == "@user.name"
      assert mention1.position == {16, 26}
      assert mention2.value == "@other-handle"
      assert mention2.position == {27, 40}
      assert mention3.value == "@third_name"
      assert mention3.position == {41, 52}
    end

    test "does not parse domain-name handles as URLs" do
      text = "Hey @solnic.dev and https://example.com"
      result = TextParser.parse(text)

      assert length(result.urls) == 1
      [url] = result.urls
      assert url.value == "https://example.com"
      assert url.position == {20, 39}

      assert length(result.mentions) == 1
      [mention] = result.mentions
      assert mention.value == "@solnic.dev"
      assert mention.position == {4, 15}
    end
  end
end
