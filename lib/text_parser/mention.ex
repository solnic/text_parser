defmodule TextParser.Tokens.Mention do
  defstruct [:value, :position]

  @type t :: %__MODULE__{
          value: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

  @mention_regex ~r/(?:^|\s)(@\S*)/u

  @doc """
  Extracts mentions from the given text.
  """
  def extract(text) when is_binary(text) do
    Regex.scan(@mention_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {mention_start, mention_length}],
                          acc ->
      absolute_start = match_start + (mention_start - match_start)
      mention_text = binary_part(text, absolute_start, mention_length)

      clean_mention = String.replace(mention_text, ~r/[^\w\-]+$/u, "")

      if is_valid?(clean_mention) do
        mention = %__MODULE__{
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

  @doc """
  Validates if the given text is a valid mention.
  """
  def is_valid?(mention_text) when is_binary(mention_text) do
    case mention_text do
      "@" <> rest ->
        rest != "" and String.match?(rest, ~r/^\S+$/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
