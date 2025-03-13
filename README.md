# TextParser

[![CI](https://github.com/solnic/text_parser/actions/workflows/ci.yml/badge.svg)](https://github.com/solnic/text_parser/actions/workflows/ci.yml) [![Hex pm](https://img.shields.io/hexpm/v/text_parser.svg?style=flat)](https://hex.pm/packages/text_parser) [![hex.pm downloads](https://img.shields.io/hexpm/dt/text_parser.svg?style=flat)](https://hex.pm/packages/text_parser)

TextParser is an Elixir library for extracting and validating structured tokens from text, such as URLs, hashtags, and mentions. It provides built-in token types and allows you to define custom parsers with specific validation rules.

This library was extracted from [justcrosspost.app](https://justcrosspost.app) where processing tags, mentions and URLs for Bluesky is [kinda tricky](https://docs.bsky.app/docs/advanced-guides/post-richtext).

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

### Custom Tokens

You can create custom token types to extract different patterns from text. Here's an example of a token that extracts ISO 8601 dates:

```elixir
defmodule MyParser.Tokens.Date do
  use TextParser.Token,
    # Match YYYY-MM-DD format, requiring space or start of string before the date
    pattern: ~r/(?:^|\s)(\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01]))/,
    trim_chars: [",", ".", "!", "?"]

  @impl true
  def is_valid?(date_text) when is_binary(date_text) do
    case Date.from_iso8601(date_text) do
      {:ok, _date} -> true
      _ -> false
    end
  end

  def is_valid?(_), do: false
end

# Usage
text = "Meeting on 2024-01-15, conference on 2024-02-30, party on 2024-12-31!"
result = TextParser.parse(text, extract: [MyParser.Tokens.Date])

dates = TextParser.get(result, MyParser.Tokens.Date)
# => [
#   %MyParser.Tokens.Date{value: "2024-01-15", position: {11, 21}},
#   %MyParser.Tokens.Date{value: "2024-12-31", position: {47, 57}}
# ]
# Note: 2024-02-30 is filtered out as it's not a valid date
```

Custom tokens require:
1. A regex `pattern` that captures the token in the first capture group
2. Optional `trim_chars` to remove trailing punctuation
3. An `is_valid?/1` function that validates the extracted value

You can mix custom tokens with built-in ones:

```elixir
alias TextParser.Tokens.{URL, Tag}
alias MyParser.Tokens.Date

result = TextParser.parse(
  "Meeting on 2024-01-15 at https://example.com #elixir",
  extract: [URL, Tag, Date]
)

TextParser.get(result, Date)  # => [%Date{value: "2024-01-15", position: {11, 21}}]
TextParser.get(result, URL)   # => [%URL{value: "https://example.com", position: {25, 44}}]
TextParser.get(result, Tag)   # => [%Tag{value: "#elixir", position: {45, 52}}]
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

:warning: The `position` tuple uses a range format where:

- The start position is inclusive (the first byte of the token)
- The end position is exclusive (one byte past the last byte of the token)

For example, with `position: {6, 29}`, the token starts at byte 6 and ends at byte 28. This format makes it easy to:
- Calculate token length: `end - start` (29 - 6 = 23 bytes)
- Extract the token from text: `binary_part(text, start, end - start)`

## Documentation

The full documentation can be found at [https://hexdocs.pm/text_parser](https://hexdocs.pm/text_parser).
