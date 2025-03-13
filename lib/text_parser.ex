defmodule TextParser do
  alias TextParser.Text
  alias TextParser.Tokens.{URL, Tag, Mention}

  @doc """
  Parses the given text and returns a Text struct with extracted URLs, tags, and mentions.
  """
  @spec parse(String.t()) :: Text.t()
  def parse(text) when is_binary(text) do
    parse(text, [])
  end

  @doc """
  Parses the given text and returns a Text struct with only the specified tokens extracted.

  ## Options

    * `:extract` - A list of token types to extract. Valid values are `:urls`, `:tags`, and `:mentions`.
      When not provided or empty, all token types are extracted.

  ## Examples

      iex> TextParser.parse("Check out https://example.com #elixir", extract: [:urls])

      iex> TextParser.parse("Check out https://example.com #elixir", extract: [:tags, :urls])

      iex> TextParser.parse("Check out https://example.com by @janedoe", extract: [:mentions, :urls])
  """
  @spec parse(String.t(), keyword()) :: Text.t()
  def parse(text, opts) when is_binary(text) and is_list(opts) do
    text = :unicode.characters_to_binary(text)
    tokens = Keyword.get(opts, :extract, [:urls, :tags, :mentions])

    urls = if :urls in tokens, do: URL.extract(text), else: []
    tags = if :tags in tokens, do: Tag.extract(text), else: []
    mentions = if :mentions in tokens, do: Mention.extract(text), else: []

    %{Text.new(text) | urls: urls, tags: tags, mentions: mentions}
  end
end
