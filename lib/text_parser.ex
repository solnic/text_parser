defmodule TextParser do
  alias TextParser.Text
  alias TextParser.Tokens.{URL, Tag, Mention}

  @doc """
  When used, defines a custom parser module.

  ## Example

      defmodule MyParser do
        use TextParser

        def validate(%TextParser.Tokens.Tag{value: value} = tag) do
          if String.length(value) >= 66, do: {:error, "tag too long"}, else: {:ok, tag}
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour TextParser.Behaviour

      def parse(text, opts \\ []) do
        opts = Keyword.put_new(opts, :extract, [URL, Tag, Mention])
        TextParser.parse(text, opts, __MODULE__)
      end

      def validate(token), do: {:ok, token}

      defoverridable validate: 1
    end
  end

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
    parse(text, opts, nil)
  end

  @spec parse(String.t()) :: Text.t()
  def parse(text) do
    parse(text, extract: [URL, Tag, Mention])
  end

  @doc false
  def parse(text, opts, parser) when is_binary(text) and is_list(opts) do
    text = :unicode.characters_to_binary(text)
    extractors = Keyword.get(opts, :extract, [])

    tokens =
      extractors
      |> Enum.flat_map(& &1.extract(text))
      |> maybe_validate(parser)
      |> Enum.sort_by(& &1.position)

    %{Text.new(text) | tokens: tokens}
  end

  @doc """
  Returns tokens of the specified type from a Text struct.

  ## Examples

      iex> text = TextParser.parse("Check out https://example.com #elixir")
      iex> TextParser.get(text, URL)
      [%TextParser.Tokens.URL{value: "https://example.com", position: {10, 29}}]
  """
  @spec get(Text.t(), module()) :: [struct()]
  def get(%Text{} = text, token_module) do
    Enum.filter(text.tokens, &match?(^token_module, &1.__struct__))
  end

  defp maybe_validate(tokens, nil), do: tokens

  defp maybe_validate(tokens, parser) do
    Enum.reduce(tokens, [], fn token, acc ->
      case parser.validate(token) do
        {:ok, token} -> [token | acc]
        {:error, _reason} -> acc
      end
    end)
    |> Enum.reverse()
  end
end
