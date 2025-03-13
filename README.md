# TextParser

[![CI](https://github.com/solnic/text_parser/actions/workflows/ci.yml/badge.svg)](https://github.com/solnic/text_parser/actions/workflows/ci.yml) [![Hex pm](https://img.shields.io/hexpm/v/text_parser.svg?style=flat)](https://hex.pm/packages/text_parser) [![hex.pm downloads](https://img.shields.io/hexpm/dt/text_parser.svg?style=flat)](https://hex.pm/packages/text_parser)

TextParser is an Elixir library for extracting and validating structured tokens from text, such as URLs, hashtags, and mentions. It provides built-in token types and allows you to define custom parsers with specific validation rules.

## Installation

Add `text_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:text_parser, "~> 0.1"}
  ]
end
```

## Usage

### Basic Parsing

By default, TextParser extracts URLs, hashtags, and mentions:

```elixir
text = "Check out https://elixir-lang.org #elixir @joe"

result = TextParser.parse(text)

# Get URLs
urls = TextParser.get(result, TextParser.Tokens.URL)
# => [%TextParser.Tokens.URL{value: "https://elixir-lang.org", position: {10, 32}}]

# Get hashtags
tags = TextParser.get(result, TextParser.Tokens.Tag)
# => [%TextParser.Tokens.Tag{value: "#elixir", position: {33, 40}}]

# Get mentions
mentions = TextParser.get(result, TextParser.Tokens.Mention)
# => [%TextParser.Tokens.Mention{value: "@joe", position: {41, 45}}]
```

### Selective Token Extraction

You can specify which token types to extract:

```elixir
alias TextParser.Tokens.{URL, Tag}

# Extract only URLs and hashtags
result = TextParser.parse("Check out https://elixir-lang.org #elixir @joe", extract: [URL, Tag])

TextParser.get(result, URL) # => [%URL{...}]
TextParser.get(result, Tag) # => [%Tag{...}]
```

### Custom Parsers

You can create custom parsers with specific validation rules:

```elixir
defmodule BlueskyParser do
  use TextParser

  alias TextParser.Tokens.Tag

  # Enforce Bluesky's 64-character limit for hashtags
  def validate(%Tag{value: value} = tag) do
    if String.length(value) >= 66,
      do: {:error, "tag too long"},
      else: {:ok, tag}
  end

  # Allow other token types to pass through
  def validate(token), do: {:ok, token}
end

# Usage
text = "Check out #elixir and #this_is_a_very_long_hashtag_that_exceeds_bluesky_limit"

result = BlueskyParser.parse(text)

# Only valid tags are included
TextParser.get(result, Tag)
# => [%Tag{value: "#elixir", position: {10, 17}}]
```

### Token Information

Each token includes its value and position in the original text:

```elixir
text = "Check https://elixir-lang.org #elixir"
result = TextParser.parse(text)

[url] = TextParser.get(result, TextParser.Tokens.URL)

url.value     # => "https://elixir-lang.org"
url.position  # => {6, 29} (start and end byte positions)
```

## Documentation

The full documentation can be found at [https://hexdocs.pm/text_parser](https://hexdocs.pm/text_parser).
