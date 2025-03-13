defmodule TextParser.Tokens.Mention do
  use TextParser.Token,
    pattern: ~r/(?:^|\s)(@\S*)/u,
    trim_chars: [".", ",", "!", "?"]

  @impl true
  def is_valid?(mention_text) when is_binary(mention_text) do
    case mention_text do
      "@" <> rest -> rest != "" and String.match?(rest, ~r/^\S+$/)
      _ -> false
    end
  end

  def is_valid?(_), do: false
end
