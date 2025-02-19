defmodule TextParser do
  alias TextParser.Text
  alias TextParser.Tokens.{URL, Tag, Mention}

  @url_regex ~r/(?:^|\s)(?<!@)((?:https?:\/\/)?[^\s]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)/ui

  @tag_regex ~r/(?:^|\s)(#[^\d\s]\S*)/u

  @mention_regex ~r/(?:^|\s)(@\S*)/u

  @max_tag_length 66

  @doc """
  Parses the given text and returns a Text struct with extracted URLs, tags, and mentions.
  """
  def parse(text) when is_binary(text) do
    text = :unicode.characters_to_binary(text)
    urls = extract_urls(text)
    tags = extract_tags(text)
    mentions = extract_mentions(text)

    %{Text.new(text) | urls: urls, tags: tags, mentions: mentions}
  end

  defp extract_urls(text) do
    Regex.scan(@url_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {url_start, url_length}], acc ->
      absolute_start = match_start + (url_start - match_start)
      uri = binary_part(text, absolute_start, url_length)

      if String.starts_with?(uri, "@") do
        acc
      else
        cleaned_uri =
          uri
          |> String.trim_trailing(".")
          |> String.trim_trailing(",")
          |> String.trim_trailing(";")
          |> String.trim_trailing("!")
          |> String.trim_trailing("?")
          |> String.trim_trailing(")")

        if URL.is_valid?(cleaned_uri) do
          url = %URL{
            value: cleaned_uri,
            position: {absolute_start, absolute_start + byte_size(cleaned_uri)}
          }

          [url | acc]
        else
          acc
        end
      end
    end)
    |> Enum.reverse()
  end

  defp extract_tags(text) do
    Regex.scan(@tag_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {tag_start, tag_length}], acc ->
      absolute_start = match_start + (tag_start - match_start)
      tag_text = binary_part(text, absolute_start, tag_length)

      if byte_size(tag_text) > @max_tag_length do
        acc
      else
        clean_tag = String.replace(tag_text, ~r/[^\w\-]+$/u, "")

        if Tag.is_valid?(clean_tag) do
          tag = %Tag{
            value: clean_tag,
            position: {absolute_start, absolute_start + byte_size(clean_tag)}
          }

          [tag | acc]
        else
          acc
        end
      end
    end)
    |> Enum.reverse()
  end

  defp extract_mentions(text) do
    Regex.scan(@mention_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {mention_start, mention_length}],
                          acc ->
      absolute_start = match_start + (mention_start - match_start)
      mention_text = binary_part(text, absolute_start, mention_length)

      clean_mention = String.replace(mention_text, ~r/[^\w\-]+$/u, "")

      if Mention.is_valid?(clean_mention) do
        mention = %Mention{
          value: clean_mention,
          position: {absolute_start, absolute_start + byte_size(clean_mention)}
        }

        [mention | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end
end
