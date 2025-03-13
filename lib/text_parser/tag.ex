defmodule TextParser.Tokens.Tag do
  use TextParser.Token,
    pattern: ~r/(?:^|\s)(#[^\d\s]\S*)/u,
    trim_chars: [".", ",", "!", "?"]

  @max_tag_length 66

  @impl true
  def is_valid?(tag_text) when is_binary(tag_text) do
    case tag_text do
      "#" <> rest when byte_size(tag_text) <= @max_tag_length ->
        rest != "" and
          String.match?(rest, ~r/^\S+$/) and
          String.match?(rest, ~r/[[:alpha:]]/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
