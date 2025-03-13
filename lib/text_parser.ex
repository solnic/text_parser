defmodule TextParser do
  alias TextParser.Text
  alias TextParser.Tokens.{URL, Tag, Mention}

  @doc """
  Parses the given text and returns a Text struct with extracted URLs, tags, and mentions.
  """
  @spec parse(String.t()) :: Text.t()
  def parse(text) when is_binary(text) do
    text = :unicode.characters_to_binary(text)
    urls = URL.extract(text)
    tags = Tag.extract(text)
    mentions = Mention.extract(text)

    %{Text.new(text) | urls: urls, tags: tags, mentions: mentions}
  end
end
