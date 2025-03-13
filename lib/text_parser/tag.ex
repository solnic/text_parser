defmodule TextParser.Tokens.Tag do
  use TextParser.Token

  @tag_regex ~r/(?:^|\s)(#[^\d\s]\S*)/u

  @max_tag_length 66

  @doc """
  Extracts tags from the given text.
  """
  @impl true
  def extract(text) when is_binary(text) do
    Regex.scan(@tag_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {tag_start, tag_length}], acc ->
      absolute_start = match_start + (tag_start - match_start)
      tag_text = binary_part(text, absolute_start, tag_length)

      if byte_size(tag_text) > @max_tag_length do
        acc
      else
        clean_tag = String.replace(tag_text, ~r/[^\w\-]+$/u, "")

        if is_valid?(clean_tag) do
          tag = %__MODULE__{
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

  @doc """
  Validates if the given text is a valid tag.
  """
  def is_valid?(tag_text) when is_binary(tag_text) do
    case tag_text do
      "#" <> rest ->
        rest != "" and
          String.match?(rest, ~r/^\S+$/) and
          String.match?(rest, ~r/[[:alpha:]]/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
