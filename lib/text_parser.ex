defmodule TextParser do
  alias TextParser.Text
  alias TextParser.Tokens.{URL, Tag, Mention}

  @doc """
  Parses the given text and returns a Text struct with extracted tokens.

  ## Options

    * `:extract` - A list of token extractor modules that implement the `TextParser.Token` behaviour.

  ## Examples

      # Extract URLs only
      iex> TextParser.parse("Check out https://example.com", extract: [URL])
      %TextParser.Text{
        value: "Check out https://example.com",
        tokens: [
          %TextParser.Tokens.URL{
            value: "https://example.com",
            position: {10, 29}
          }
        ]
      }

      # Extract URLs and tags
      iex> TextParser.parse("Check out https://example.com #elixir", extract: [URL, Tag])
      %TextParser.Text{
        value: "Check out https://example.com #elixir",
        tokens: [
          %TextParser.Tokens.URL{
            value: "https://example.com",
            position: {10, 29}
          },
          %TextParser.Tokens.Tag{
            value: "#elixir",
            position: {30, 37}
          }
        ]
      }

  """
  @spec parse(String.t(), keyword()) :: Text.t()
  def parse(text, opts) when is_binary(text) and is_list(opts) do
    text = :unicode.characters_to_binary(text)
    extractors = Keyword.get(opts, :extract, [])

    tokens = Enum.flat_map(extractors, & &1.extract(text))
    %{Text.new(text) | tokens: Enum.sort_by(tokens, & &1.position)}
  end

  @spec parse(String.t()) :: Text.t()
  def parse(text) do
    parse(text, extract: [URL, Tag, Mention])
  end
end
